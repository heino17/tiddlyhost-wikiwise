namespace :thumbnails do
  desc 'Regenerate site thumbnails (KIND=site|tspot, SITE=name, LIMIT=n, DRY_RUN=1)'
  task regenerate: :environment do
    kind = ENV.fetch('KIND', nil)
    models =
      case kind
      when 'site' then [Site]
      when 'tspot' then [TspotSite]
      when nil, '' then [Site, TspotSite]
      else abort "Unknown KIND #{kind.inspect} (expected site or tspot)"
      end

    only_site = ENV['SITE'].presence
    limit = ENV['LIMIT'].presence&.to_i
    dry_run = ENV['DRY_RUN'].to_s.match?(/\A(1|true|yes)\z/i)

    processed = 0
    failures = []

    models.each do |model|
      scope = model.all
      scope = scope.where(name: only_site) if only_site

      scope.find_each do |site|
        break if limit && processed >= limit
        next if site.current_content.blank?

        processed += 1
        label = "#{model.name} #{site.name}"

        if dry_run
          puts "#{label}: would regenerate"
          next
        end

        started = Time.now
        begin
          # Thumbnail generation is expensive; it spins up headless chrome.
          # This is the same private entry point used by GenerateThumbnailJob.
          site.send(:update_thumbnail_now)
          site.reload
          width, height = site.thumbnail.download[16, 8].unpack('NN')
          elapsed = Time.now - started
          puts "#{label}: #{width}x#{height}, #{site.thumbnail.blob.byte_size} bytes, #{format('%.1f', elapsed)}s"
        rescue StandardError => e
          failures << [label, e]
          puts "#{label}: FAILED (#{e.class}: #{e.message})"
        end
      end
    end

    if failures.any?
      puts "#{failures.size} failure(s):"
      failures.each { |label, e| puts " - #{label}: #{e.class}: #{e.message}" }
      abort 'Thumbnail regeneration finished with errors.'
    end

    puts "Done. #{dry_run ? 'Would have regenerated' : 'Regenerated'} #{processed} thumbnail(s)."
  end
end
