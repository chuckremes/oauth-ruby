# frozen_string_literal: true

require File.expand_path("../test_helper", __dir__)

require "oauth/consumer"
require "oauth/signature/rsa/sha1"

class TestSignatureRsaSha1 < Minitest::Test
  def setup
    @request = Net::HTTP::Get.new("/photos?file=vacaction.jpg&size=original&oauth_version=1.0&oauth_consumer_key=#{consumer_key}&oauth_timestamp=1196666512&oauth_nonce=13917289812797014437&oauth_signature_method=RSA-SHA1")

    @consumer = OAuth::Consumer.new(consumer_key, pkey_rsa)
  end

  def test_that_rsa_sha1_implements_rsa_sha1
    assert_includes OAuth::Signature.available_methods, "rsa-sha1"
  end

  def test_that_get_request_from_oauth_test_cases_produces_matching_signature_base_string
    sbs = OAuth::Signature.signature_base_string(@request, { consumer: @consumer,
                                                             uri: "http://photos.example.net/photos" })

    assert_equal "GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacaction.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3D13917289812797014437%26oauth_signature_method%3DRSA-SHA1%26oauth_timestamp%3D1196666512%26oauth_version%3D1.0%26size%3Doriginal",
                 sbs
  end

  def test_that_get_request_from_oauth_test_cases_produces_matching_signature
    signature = OAuth::Signature.sign(@request, { consumer: @consumer,
                                                  uri: "http://photos.example.net/photos" })

    assert_equal "jvTp/wX1TYtByB1m+Pbyo0lnCOLIsyGCH7wke8AUs3BpnwZJtAuEJkvQL2/9n4s5wUmUl4aCI4BwpraNx4RtEXMe5qg5T1LVTGliMRpKasKsW//e+RinhejgCuzoH26dyF8iY2ZZ/5D1ilgeijhV/vBka5twt399mXwaYdCwFYE=",
                 signature
  end

  def test_that_get_request_from_oauth_test_cases_produces_matching_signature_using_private_key_file
    @consumer = OAuth::Consumer.new(consumer_key, nil)

    signature = OAuth::Signature.sign(@request, { consumer: @consumer,
                                                  private_key_file: pem_path,
                                                  uri: "http://photos.example.net/photos" })

    assert_equal "jvTp/wX1TYtByB1m+Pbyo0lnCOLIsyGCH7wke8AUs3BpnwZJtAuEJkvQL2/9n4s5wUmUl4aCI4BwpraNx4RtEXMe5qg5T1LVTGliMRpKasKsW//e+RinhejgCuzoH26dyF8iY2ZZ/5D1ilgeijhV/vBka5twt399mXwaYdCwFYE=",
                 signature
  end

  def test_that_get_request_from_oauth_test_cases_verifies_signature
    @request = Net::HTTP::Get.new("/photos?oauth_signature_method=RSA-SHA1&oauth_version=1.0&oauth_consumer_key=#{consumer_key}&oauth_timestamp=1196666512&oauth_nonce=13917289812797014437&file=vacaction.jpg&size=original&oauth_signature=jvTp%2FwX1TYtByB1m%2BPbyo0lnCOLIsyGCH7wke8AUs3BpnwZJtAuEJkvQL2%2F9n4s5wUmUl4aCI4BwpraNx4RtEXMe5qg5T1LVTGliMRpKasKsW%2F%2Fe%2BRinhejgCuzoH26dyF8iY2ZZ%2F5D1ilgeijhV%2FvBka5twt399mXwaYdCwFYE%3D")
    @consumer = OAuth::Consumer.new(consumer_key, x509_certificate)

    assert OAuth::Signature.verify(@request, { consumer: @consumer,
                                               uri: "http://photos.example.net/photos" })
  end

  def test_that_get_request_from_oauth_test_cases_verifies_signature_with_pem
    @request = Net::HTTP::Get.new("/photos?oauth_signature_method=RSA-SHA1&oauth_version=1.0&oauth_consumer_key=#{consumer_key}&oauth_timestamp=1196666512&oauth_nonce=13917289812797014437&file=vacaction.jpg&size=original&oauth_signature=jvTp%2FwX1TYtByB1m%2BPbyo0lnCOLIsyGCH7wke8AUs3BpnwZJtAuEJkvQL2%2F9n4s5wUmUl4aCI4BwpraNx4RtEXMe5qg5T1LVTGliMRpKasKsW%2F%2Fe%2BRinhejgCuzoH26dyF8iY2ZZ%2F5D1ilgeijhV%2FvBka5twt399mXwaYdCwFYE%3D")
    assert OAuth::Signature.verify(@request, { consumer: @consumer,
                                               uri: "http://photos.example.net/photos" })
  end

  private

  def consumer_key
    "dpf43f3p2l4k3l03"
  end

  def x509_certificate
    OpenSSL::X509::Certificate.new(File.read(cert_path))
  end

  def pkey_rsa
    OpenSSL::PKey::RSA.new(File.read(pem_path))
  end

  def cert_path
    "#{File.dirname(__FILE__)}/../keys/rsa.cert"
  end

  def pem_path
    "#{File.dirname(__FILE__)}/../keys/rsa.pem"
  end
end
