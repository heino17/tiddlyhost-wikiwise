require 'test_helper'

class LoginPuzzleModelTest < ActiveSupport::TestCase
  test 'generates a nine tile board with three animals' do
    tiles = LoginPuzzle.generate

    assert_equal LoginPuzzle::TILE_COUNT, tiles.size
    assert_equal LoginPuzzle::ANIMAL_COUNT, tiles.count { |tile| tile[:animal] }
    assert_equal LoginPuzzle::TILE_COUNT - LoginPuzzle::ANIMAL_COUNT,
      tiles.count { |tile| !tile[:animal] }
    assert_equal tiles.size, tiles.map { |tile| tile[:id] }.uniq.size
    assert_equal tiles.size, tiles.map { |tile| tile[:emoji] }.uniq.size
  end

  test 'answer contains only the animal tile ids in stable order' do
    tiles = LoginPuzzle.generate
    expected = tiles.select { |tile| tile[:animal] }.map { |tile| tile[:id] }.sort

    assert_equal expected, LoginPuzzle.answer_for(tiles)
  end
end
