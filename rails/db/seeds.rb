#
# Useful data for bringing up a new development environment
#
[
  UserType,
  Empty

].each do |klass|
  seed_file = "#{Rails.root}/db/seeds/#{klass.table_name}.yml"
  # Idempotent: vorhandene Zeilen (per name) updaten statt create! mit festen
  # IDs. Sonst kollidiert der Seed z.B. mit den von Migrationen angelegten
  # Empties (Duplicate-Key). Bei neuen Zeilen bleiben die IDs aus der YAML.
  YAML.load_file(seed_file).each do |attrs|
    record = klass.find_by(name: attrs["name"])
    record ? record.update!(attrs.except("id")) : klass.create!(attrs)
  end
end
