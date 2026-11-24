module LoginPuzzleTestHelper
  # Fetches a fresh puzzle and returns the params a solved login form would
  # submit. Tests that post to /users/sign_in need this since the server now
  # checks the solution as well as the password.
  def login_puzzle_params
    get login_puzzle_path
    assert_response :success

    puzzle = JSON.parse(response.body)
    answer = puzzle.fetch('tiles').select { |tile| tile['animal'] }.
      map { |tile| tile.fetch('id') }.sort.join(',')

    { token: puzzle.fetch('token'), answer: answer }
  end
end
