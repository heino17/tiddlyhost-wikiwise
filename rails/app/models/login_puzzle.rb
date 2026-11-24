# Builds the 3x3 "tap all the animals" puzzle used on the login form.
#
# The board is generated server-side so the solution can be kept in the
# session and checked again when the sign-in form is submitted. The animals
# and distractors are deliberately simple; this is a deterrent, not a
# cryptographic CAPTCHA.
class LoginPuzzle
  ANIMAL_POOL = %w[🦊 🐱 🐶 🐼 🦁 🐵 🐰 🐸 🦉].freeze
  NON_ANIMAL_POOL = %w[🍎 🍌 🍕 ☕ 🎂 ⚽ 🚗 🌵 📱 ⭐ 🎈 🌸 🚲 🍦].freeze
  ANIMAL_COUNT = 3
  TILE_COUNT = 9

  class << self
    def generate
      pairs = animals + non_animals
      pairs.shuffle.each_with_index.map do |(emoji, animal), index|
        { id: "tile-#{index + 1}", emoji: emoji, animal: animal }
      end
    end

    def answer_for(tiles)
      tiles.select { |tile| tile[:animal] }.map { |tile| tile[:id] }.sort
    end

    private

    def animals
      ANIMAL_POOL.sample(ANIMAL_COUNT).map { |emoji| [emoji, true] }
    end

    def non_animals
      NON_ANIMAL_POOL.sample(TILE_COUNT - ANIMAL_COUNT).map { |emoji| [emoji, false] }
    end
  end
end
