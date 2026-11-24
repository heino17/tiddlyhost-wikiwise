require 'test_helper'

class LoginPuzzleTest < ActionDispatch::IntegrationTest
  test 'sign in page shows the animal puzzle' do
    get '/users/sign_in'

    assert_response :success
    assert_select '.login-puzzle'
    assert_select '.login-puzzle-tile', LoginPuzzle::TILE_COUNT
    assert_select '.login-puzzle-tile[data-animal="true"]', LoginPuzzle::ANIMAL_COUNT
    assert_select 'input[name="login_puzzle[token]"]'
    assert_select 'input[name="login_puzzle[answer]"]'
  end

  test 'refresh returns a new board and token' do
    get '/users/sign_in'
    old_token = session[:login_puzzle]['token']

    get login_puzzle_path

    assert_response :success
    puzzle = JSON.parse(response.body)
    assert_not_equal old_token, puzzle['token']
    assert_equal LoginPuzzle::TILE_COUNT, puzzle['tiles'].size
    assert_equal LoginPuzzle::ANIMAL_COUNT, puzzle['tiles'].count { |tile| tile['animal'] }
    assert_equal puzzle['token'], session[:login_puzzle]['token']
  end

  test 'login without the puzzle is rejected' do
    user = puzzle_user

    post '/users/sign_in', params: {
      user: { email: user.email, password: 'Abcd1234' },
    }

    assert_redirected_to '/users/sign_in'
    assert_equal I18n.t('login_puzzle_error'), flash[:alert]

    get '/users/edit'
    assert_redirected_to '/users/sign_in'
  end

  test 'login with a wrong puzzle answer is rejected' do
    user = puzzle_user
    puzzle = login_puzzle_params

    post '/users/sign_in', params: {
      user: { email: user.email, password: 'Abcd1234' },
      login_puzzle: { token: puzzle[:token], answer: 'tile-999' },
    }

    assert_redirected_to '/users/sign_in'
    assert_equal I18n.t('login_puzzle_error'), flash[:alert]
  end

  test 'login with the solved puzzle succeeds' do
    user = puzzle_user
    puzzle = login_puzzle_params

    post '/users/sign_in', params: {
      user: { email: user.email, password: 'Abcd1234' },
      login_puzzle: puzzle,
    }

    assert_redirected_to '/'

    get '/users/edit'
    assert_response :success
  end

  private

  def puzzle_user
    @puzzle_user ||= begin
      hex = SecureRandom.hex(4)
      user = User.new(
        email: "puzzle-#{hex}@example.com",
        name: 'Puzzle User',
        username: "puzzle-#{hex}",
        password: 'Abcd1234',
      )
      user.skip_confirmation!
      user.save!
      user
    end
  end
end
