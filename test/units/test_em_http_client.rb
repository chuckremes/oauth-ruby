# frozen_string_literal: true

require File.expand_path("../test_helper", __dir__)
begin
  require "oauth/client/em_http"

  class EmHttpClientTest < Minitest::Test
    def setup
      @consumer = OAuth::Consumer.new("consumer_key_86cad9", "5888bf0345e5d237")
      @token = OAuth::Token.new("token_411a7f", "3196ffd991c8ebdb")
      @request_uri = URI.parse("http://example.com/test?key=value")
      @request_parameters = { "key" => "value" }
      @nonce = 225_579_211_881_198_842_005_988_698_334_675_835_446
      @timestamp = "1199645624"
      # This is really unneeded I guess.
      @http = Net::HTTP.new(@request_uri.host, @request_uri.port)
    end

    def test_that_using_auth_headers_on_get_requests_works
      request = create_client
      request.oauth!(@http, @consumer, @token, { nonce: @nonce, timestamp: @timestamp })

      assert_equal "GET", request.req[:method]
      assert_equal "/test", request.normalize_uri.path
      assert_equal "key=value", request.normalize_uri.query
      correct_headers = "OAuth oauth_nonce=\"225579211881198842005988698334675835446\", oauth_signature_method=\"HMAC-SHA1\", oauth_token=\"token_411a7f\", oauth_timestamp=\"1199645624\", oauth_consumer_key=\"consumer_key_86cad9\", oauth_signature=\"1oO2izFav1GP4kEH2EskwXkCRFg%3D\", oauth_version=\"1.0\""
      generated_headers = authz_header(request)
      assert_equal_authz_headers correct_headers, generated_headers
    end

    def test_that_using_auth_headers_on_get_requests_works_with_plaintext
      c = OAuth::Consumer.new("consumer_key_86cad9", "5888bf0345e5d237", {
                                signature_method: "PLAINTEXT"
                              })
      request = create_client
      request.oauth!(@http, c, @token, { nonce: @nonce, timestamp: @timestamp, signature_method: "PLAINTEXT" })

      assert_equal "GET", request.req[:method]
      assert_equal "/test", request.conn.path
      assert_equal "key=value", request.conn.query
      assert_equal_authz_headers "OAuth oauth_nonce=\"225579211881198842005988698334675835446\", oauth_signature_method=\"PLAINTEXT\", oauth_token=\"token_411a7f\", oauth_timestamp=\"1199645624\", oauth_consumer_key=\"consumer_key_86cad9\", oauth_signature=\"5888bf0345e5d237%263196ffd991c8ebdb\", oauth_version=\"1.0\"",
                                 authz_header(request)
    end

    def test_that_using_auth_headers_on_post_requests_works
      request = create_client(uri: "http://example.com/test", method: "POST", body: @request_parameters,
                              head: { "Content-Type" => "application/x-www-form-urlencoded" })
      request.oauth!(@http, @consumer, @token, { nonce: @nonce, timestamp: @timestamp })

      assert_equal "POST", request.req[:method]
      assert_equal "/test", request.conn.path
      assert_equal_authz_headers "OAuth oauth_nonce=\"225579211881198842005988698334675835446\", oauth_signature_method=\"HMAC-SHA1\", oauth_token=\"token_411a7f\", oauth_timestamp=\"1199645624\", oauth_consumer_key=\"consumer_key_86cad9\", oauth_signature=\"26g7wHTtNO6ZWJaLltcueppHYiI%3D\", oauth_version=\"1.0\"",
                                 authz_header(request)
      assert_equal "key=value", request.normalize_body(request.req[:body])
    end

    protected

    def create_client(options = {})
      options[:method] = options.key?(:method) ? options[:method].upcase : "GET"
      uri = options.delete(:uri) || @request_uri.to_s
      EventMachine::HttpClient.new(URI.parse(uri), options)
    end

    def authz_header(request)
      request.req[:head]["Authorization"]
    end

    def assert_equal_authz_headers(expected, actual)
      refute_nil actual
      assert_equal expected[0, 6], actual[0, 6]
      assert_equal expected[6..1].split(", ").sort, actual[6..1].split(", ").sort
    end
  end
rescue LoadError => e
  warn "! problem loading em-http, skipping these tests: #{e}"
end
