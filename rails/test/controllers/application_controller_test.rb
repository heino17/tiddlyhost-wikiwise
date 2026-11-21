require "test_helper"

class ApplicationControllerTest < ActiveSupport::TestCase
  test "navbar_prod is active in production regardless of domain" do
    Rails.stubs(:env).returns(ActiveSupport::StringInquirer.new("production"))

    assert_equal "navbar-prod", ApplicationController.new.send(:navbar_prod)
  end

  test "navbar_prod stays inactive in development" do
    Rails.stubs(:env).returns(ActiveSupport::StringInquirer.new("development"))

    assert_nil ApplicationController.new.send(:navbar_prod)
  end
end
