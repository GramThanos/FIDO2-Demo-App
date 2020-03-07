require 'test_helper'

class AppControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get app_index_url
    assert_response :success
  end

  test "should get login" do
    get app_login_url
    assert_response :success
  end

  test "should get register" do
    get app_register_url
    assert_response :success
  end

  test "should get dashboard" do
    get app_dashboard_url
    assert_response :success
  end

end
