namespace :active_storage do
  desc "Dry-run: Zeigt verwaiste ActiveStorage-Blobs und Dateien"
  task dry_run: :environment do
    puts "🔍 Suche verwaiste Blobs…"
    orphaned_blobs = ActiveStorage::Blob.left_outer_joins(:attachments)
                                        .where(active_storage_attachments: { id: nil })

    puts "Gefundene verwaiste Blobs: #{orphaned_blobs.count}"
    orphaned_blobs.each do |blob|
      puts " - Blob ##{blob.id} (#{blob.filename}, key=#{blob.key})"
    end

    puts "\n🔍 Suche verwaiste Dateien im storage/-Ordner…"
    storage_path = Rails.root.join("storage")
    used_keys = ActiveStorage::Blob.pluck(:key)

    all_files = Dir.glob("#{storage_path}/**/*").select { |f| File.file?(f) }
    orphaned_files = all_files.reject { |f| used_keys.any? { |key| f.include?(key) } }

    puts "Gefundene verwaiste Dateien: #{orphaned_files.count}"
    orphaned_files.each { |file| puts " - #{file}" }

    puts "\n💡 Dry-run abgeschlossen. Keine Daten wurden gelöscht."
  end

  desc "Löscht verwaiste ActiveStorage-Blobs und Dateien"
  task cleanup: :environment do
    puts "🧹 Lösche verwaiste Blobs…"
    orphaned_blobs = ActiveStorage::Blob.left_outer_joins(:attachments)
                                        .where(active_storage_attachments: { id: nil })

    orphaned_blobs.find_each do |blob|
      puts " - Lösche Blob ##{blob.id} (#{blob.filename})"
      blob.purge
    end

    puts "\n🧹 Lösche verwaiste Dateien im storage/-Ordner…"
    storage_path = Rails.root.join("storage")
    used_keys = ActiveStorage::Blob.pluck(:key)

    all_files = Dir.glob("#{storage_path}/**/*").select { |f| File.file?(f) }
    orphaned_files = all_files.reject { |f| used_keys.any? { |key| f.include?(key) } }

    orphaned_files.each do |file|
      puts " - Lösche Datei #{file}"
      File.delete(file)
    end

    puts "\n✅ Cleanup abgeschlossen."
  end
end
