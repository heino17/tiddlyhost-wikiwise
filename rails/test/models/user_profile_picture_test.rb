require 'test_helper'

class UserProfilePictureTest < ActiveSupport::TestCase
  include ProfilePictureTestHelper

  setup do
    @user = users(:bobby)
  end

  test 'accepts an image within the size and dimension limits' do
    @user.profile_picture = uploaded_png(width: 64, height: 64)

    assert @user.save
    assert @user.reload.profile_picture.attached?
    assert_equal [64, 64], @user.profile_picture_dimensions
  end

  test 'rejects images larger than 100 KB' do
    @user.profile_picture = uploaded_png(width: 64, height: 64, padding: 101 * 1024)

    refute @user.save
    assert @user.errors[:profile_picture].any? { |message| message.include?('100 KB') }
  end

  test 'rejects images wider or taller than 256 pixels' do
    @user.profile_picture = uploaded_png(width: 257, height: 100)

    refute @user.save
    assert @user.errors[:profile_picture].any? { |message| message.include?('256') }
  end

  test 'rejects unsupported content types' do
    @user.profile_picture = uploaded_text

    refute @user.save
    assert @user.errors[:profile_picture].any?
  end

  test 'removes the picture when requested' do
    @user.profile_picture = uploaded_png(width: 64, height: 64)
    assert @user.save
    assert @user.profile_picture.attached?

    @user.remove_profile_picture = true
    assert @user.save

    assert_not @user.reload.profile_picture.attached?
  end

  test 'own picture makes use_avatar? true without external avatars' do
    @user.use_gravatar = false
    @user.use_libravatar = false
    refute @user.use_avatar?

    @user.profile_picture = uploaded_png(width: 32, height: 32)
    assert @user.save

    assert @user.reload.use_avatar?
  end
end
