require 'test_helper'

class FidoControllerTest < ActionDispatch::IntegrationTest
  test "should get auth" do
    get fido_auth_url
    assert_response :success
  end

  test "should get register" do
    get fido_register_url
    assert_response :success
  end

  test "should get keys" do
    get fido_keys_url
    assert_response :success
  end

end
