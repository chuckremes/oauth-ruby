# frozen_string_literal: true

require File.expand_path("../test_helper", __dir__)

# This performs testing against Andy Smith's test server http://term.ie/oauth/example/
# Thanks Andy.
# This also means you have to be online to be able to run these.
class ConsumerTest < Minitest::Test
  def setup
    @consumer = OAuth::Consumer.new(
      "consumer_key_86cad9", "5888bf0345e5d237",
      {
        site: "http://blabla.bla",
        proxy: "http://user:password@proxy.bla:8080",
        request_token_path: "/oauth/example/request_token.php",
        access_token_path: "/oauth/example/access_token.php",
        authorize_path: "/oauth/example/authorize.php",
        scheme: :header,
        http_method: :get
      }
    )
    @token = OAuth::ConsumerToken.new(@consumer, "token_411a7f", "3196ffd991c8ebdb")
    @request_uri = URI.parse("http://example.com/test?key=value")
    @request_parameters = { "key" => "value" }
    @nonce = 225_579_211_881_198_842_005_988_698_334_675_835_446
    @timestamp = "1199645624"
    @consumer.http = Net::HTTP.new(@request_uri.host, @request_uri.port)
  end

  def test_initializer
    assert_equal "consumer_key_86cad9", @consumer.key
    assert_equal "5888bf0345e5d237", @consumer.secret
    assert_equal "http://blabla.bla", @consumer.site
    assert_equal "http://user:password@proxy.bla:8080", @consumer.proxy
    assert_equal "/oauth/example/request_token.php", @consumer.request_token_path
    assert_equal "/oauth/example/access_token.php", @consumer.access_token_path
    assert_equal "http://blabla.bla/oauth/example/request_token.php", @consumer.request_token_url
    assert_equal "http://blabla.bla/oauth/example/access_token.php", @consumer.access_token_url
    assert_equal "http://blabla.bla/oauth/example/authorize.php", @consumer.authorize_url
    assert_equal :header, @consumer.scheme
    assert_equal :get, @consumer.http_method
    assert_nil   @consumer.debug_output
  end

  def test_defaults
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        site: "http://twitter.com"
      }
    )
    assert_equal "key", @consumer.key
    assert_equal "secret", @consumer.secret
    assert_equal "http://twitter.com", @consumer.site
    assert_nil @consumer.proxy
    assert_equal "/oauth/request_token", @consumer.request_token_path
    assert_equal "/oauth/access_token", @consumer.access_token_path
    assert_equal "http://twitter.com/oauth/request_token", @consumer.request_token_url
    assert_equal "http://twitter.com/oauth/access_token", @consumer.access_token_url
    assert_equal "http://twitter.com/oauth/authorize", @consumer.authorize_url
    assert_equal :header, @consumer.scheme
    assert_equal :post, @consumer.http_method
    assert_nil   @consumer.debug_output
  end

  def test_debug_output_true
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        debug_output: true
      }
    )
    assert_equal $stdout, @consumer.debug_output
  end

  def test_debug_output
    stringio = StringIO.new
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        debug_output: stringio
      }
    )
    assert_equal stringio, @consumer.debug_output
  end

  def test_site_without_path
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        site: "http://twitter.com"
      }
    )
    request = stub(oauth!: nil)
    http = stub(request: stub(to_hash: {}), address: "identi.ca")
    Net::HTTP::Get.expects(:new).with("/people", {}).returns(request)
    @consumer.expects(:create_http).returns(http)
    @consumer.request(:get, "/people", nil, {})
  end

  def test_site_with_path
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        site: "http://identi.ca/api"
      }
    )
    request = stub(oauth!: nil)
    http = stub(request: stub(to_hash: {}), address: "identi.ca")
    Net::HTTP::Get.expects(:new).with("/api/people", {}).returns(request)
    @consumer.expects(:create_http).returns(http)
    @consumer.request(:get, "/people", nil, {})
  end

  def test_post_of_nested_params_maintains_nesting
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        site: "http://twitter.com"
      }
    )
    request = @consumer.create_signed_request(
      :post,
      "/people",
      nil,
      {},
      {
        key: {
          subkey: "value"
        }
      }
    )
    assert_equal "key%5Bsubkey%5D=value", request.body
    assert_equal("application/x-www-form-urlencoded", request.content_type)
  end

  def test_override_paths
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        site: "http://twitter.com",
        request_token_url: "http://oauth.twitter.com/request_token",
        access_token_url: "http://oauth.twitter.com/access_token",
        authorize_url: "http://site.twitter.com/authorize"
      }
    )
    assert_equal "key", @consumer.key
    assert_equal "secret", @consumer.secret
    assert_equal "http://twitter.com", @consumer.site
    assert_equal "/oauth/request_token", @consumer.request_token_path
    assert_equal "/oauth/access_token", @consumer.access_token_path
    assert_equal "http://oauth.twitter.com/request_token", @consumer.request_token_url
    assert_equal "http://oauth.twitter.com/access_token", @consumer.access_token_url
    assert_equal "http://site.twitter.com/authorize", @consumer.authorize_url
    assert_equal :header, @consumer.scheme
    assert_equal :post, @consumer.http_method
  end

  def test_getting_tokens_doesnt_add_paths_if_full_url_is_specified
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        site: "https://api.mysite.co.nz/v1",
        request_token_url: "https://authentication.mysite.co.nz/Oauth/RequestToken"
      }
    )

    stub_request(:post, "https://authentication.mysite.co.nz/Oauth/RequestToken").to_return(body: "success",
                                                                                            status: 200)
    @consumer.get_request_token
  end

  def test_noverify_true
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        site: "https://api.mysite.co.nz/v1",
        request_token_url: "https://authentication.mysite.co.nz/Oauth/RequestToken",
        no_verify: true
      }
    )

    stub_request(:post, "https://authentication.mysite.co.nz/Oauth/RequestToken").to_return(body: "success",
                                                                                            status: 200)

    Net::HTTP.any_instance.expects(:"verify_mode=").with(OpenSSL::SSL::VERIFY_NONE)

    @consumer.get_request_token
  end

  def test_noverify_false
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        site: "https://api.mysite.co.nz/v1",
        request_token_url: "https://authentication.mysite.co.nz/Oauth/RequestToken",
        no_verify: false
      }
    )

    stub_request(:post, "https://authentication.mysite.co.nz/Oauth/RequestToken").to_return(body: "success",
                                                                                            status: 200)

    Net::HTTP.any_instance.expects(:"verify_mode=").with(OpenSSL::SSL::VERIFY_PEER)
    @consumer.get_request_token
  end

  def test_noverify_empty
    @consumer = OAuth::Consumer.new(
      "key",
      "secret",
      {
        site: "https://api.mysite.co.nz/v1",
        request_token_url: "https://authentication.mysite.co.nz/Oauth/RequestToken"
      }
    )

    stub_request(:post, "https://authentication.mysite.co.nz/Oauth/RequestToken").to_return(body: "success",
                                                                                            status: 200)

    Net::HTTP.any_instance.expects(:"verify_mode=").with(OpenSSL::SSL::VERIFY_PEER)
    @consumer.get_request_token
  end

  def test_token_request_identifies_itself_as_a_token_request
    request_options = {}
    @consumer.stubs(:request).returns(create_stub_http_response)
    @consumer.token_request(:post, "/", "token", request_options) {}
    assert request_options[:token_request]
  end

  def test_that_token_response_should_be_uri_parameter_format_as_default
    @consumer.expects(:request).returns(create_stub_http_response("oauth_token=token&oauth_token_secret=secret"))

    hash = @consumer.token_request(:get, "")

    assert_equal "token", hash[:oauth_token]
    assert_equal "secret", hash[:oauth_token_secret]
  end

  def test_can_provided_a_block_to_interpret_token_response
    @consumer.expects(:request).returns(create_stub_http_response)

    hash = @consumer.token_request(:get, "") { { oauth_token: "token", oauth_token_secret: "secret" } }

    assert_equal "token", hash[:oauth_token]
    assert_equal "secret", hash[:oauth_token_secret]
  end

  def test_token_request_follows_redirect
    redirect_url = @request_uri.clone
    redirect_url.path = "/oauth/example/request_token_redirect.php"
    stub_request(:get, /.*#{@request_uri.path}/).to_return(status: 301,
                                                           headers: { "Location" => redirect_url.to_s })
    stub_request(:get, /.*#{redirect_url.path}/).to_return(body: "oauth_token=token&oauth_token_secret=secret")

    hash = @consumer.token_request(:get, @request_uri.path) do
      { oauth_token: "token", oauth_token_secret: "secret" }
    end

    assert_equal "token", hash[:oauth_token]
    assert_equal "secret", hash[:oauth_token_secret]
  end

  def test_follow_redirect_different_host_same_path
    request_uri = URI.parse("https://example.com/request_token")
    redirect_uri = URI.parse("https://foobar.com/request_token")

    stub_request(:get, "http://example.com/request_token").to_return(status: 301,
                                                                     headers: { "Location" => redirect_uri.to_s })
    stub_request(:get,
                 "https://foobar.com/request_token").to_return(body: "oauth_token=token&oauth_token_secret=secret")

    hash = @consumer.token_request(:get, request_uri.path) do
      { oauth_token: "token", oauth_token_secret: "secret" }
    end

    assert_equal "token", hash[:oauth_token]
    assert_equal "secret", hash[:oauth_token_secret]
  end

  def test_not_following_redirect_with_same_uri
    request_uri = URI.parse("http://example.com/request_token")
    redirect_uri = request_uri.clone

    stub_request(:get, request_uri.to_s).to_return(
      status: 301,
      headers: { "Location" => redirect_uri.to_s }
    )

    assert_raises Net::HTTPRetriableError do
      @consumer.token_request(:get, request_uri.path) do
        { oauth_token: "token", oauth_token_secret: "secret" }
      end
    end
  end

  def test_that_can_provide_a_block_to_interpret_a_request_token_response
    @consumer.expects(:request).returns(create_stub_http_response)

    token = @consumer.get_request_token { { oauth_token: "token", oauth_token_secret: "secret" } }

    assert_equal "token", token.token
    assert_equal "secret", token.secret
  end

  def test_that_block_is_not_mandatory_for_getting_an_access_token
    stub_token = mock
    @consumer.expects(:request).returns(create_stub_http_response("oauth_token=token&oauth_token_secret=secret"))

    token = @consumer.get_access_token(stub_token)

    assert_equal "token", token.token
    assert_equal "secret", token.secret
  end

  def test_that_can_provide_a_block_to_interpret_an_access_token_response
    stub_token = mock
    @consumer.expects(:request).returns(create_stub_http_response)

    token = @consumer.get_access_token(stub_token) { { oauth_token: "token", oauth_token_secret: "secret" } }

    assert_equal "token", token.token
    assert_equal "secret", token.secret
  end

  def test_that_not_setting_ignore_callback_will_include_oauth_callback_in_request_options
    request_options = {}
    @consumer.stubs(:request).returns(create_stub_http_response)

    @consumer.get_request_token(request_options) { { oauth_token: "token", oauth_token_secret: "secret" } }

    assert_equal "oob", request_options[:oauth_callback]
  end

  def test_that_setting_ignore_callback_will_exclude_oauth_callback_in_request_options
    request_options = { exclude_callback: true }
    @consumer.stubs(:request).returns(create_stub_http_response)

    @consumer.get_request_token(request_options) { { oauth_token: "token", oauth_token_secret: "secret" } }

    assert_nil request_options[:oauth_callback]
  end

  private

  def create_stub_http_response(expected_body = nil)
    stub_http_response = stub
    stub_http_response.stubs(:code).returns(200)
    stub_http_response.stubs(:body).tap { |expectation| expectation.returns(expected_body) unless expected_body.nil? }
    stub_http_response
  end
end
