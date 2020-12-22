# frozen_string_literal: true

# quick'n'dirty fixture loader
module FixturesSupport
  def fixtures_contents
    @fixtures_contents ||= begin
      fixtures_path = 'spec/fixtures'
      Dir.glob("#{fixtures_path}/**/*").inject({}) do |h, path|
        next h if File.directory?(path)

        h.update(path[fixtures_path.length + 1..-1] => Pathname.new(path).read)
      end
    end
  end
end
