module SpecHelpers
  def gloss_yml(**args)
    File.open("./.gloss.yml", "wb") do |file|
      file.puts args.transform_keys(&:to_s).to_yaml
    end
  end

  def gloss_file(path, contents)
    File.open(path, "wb") do |file|
      file.puts contents
    end
  end
end
