require 'test_helper'

class ProfilePictureDisplayTest < ActionDispatch::IntegrationTest
  include ProfilePictureTestHelper

  setup do
    @user = users(:bobby)
    @user.update!(password: 'Abcd1234')
    @user.use_gravatar = false
    @user.use_libravatar = false
    @user.profile_picture = uploaded_png(width: 48, height: 48)
    @user.save!
  end

  test 'hub user page shows the custom picture' do
    get "/explore/user/#{@user.username}"

    assert_response :success
    assert_select "img.avatar[src*='active_storage']"
  end

  test 'account edit always offers the upload' do
    sign_in @user
    get '/users/edit'

    assert_response :success
    assert_select "input[type=file][name='user[profile_picture]']"
    assert_select "img.avatar[src*='active_storage']"
  end

  test 'uploading through account edit stores the picture' do
    @user.profile_picture.purge
    sign_in @user

    put '/users', params: {
      user: {
        profile_picture: uploaded_png(width: 40, height: 40),
        current_password: 'Abcd1234',
      },
    }

    assert_redirected_to '/'
    assert @user.reload.profile_picture.attached?
  end

  test 'admin table and user details show the custom picture' do
    admin = users(:mary)
    admin.update!(user_type: UserType.superuser)
    sign_in admin

    get '/admin/users'
    assert_response :success
    assert_select "img.avatar[src*='active_storage']"

    get "/admin/users/#{@user.id}"
    assert_response :success
    assert_select "img.avatar[src*='active_storage']"
  end
end
