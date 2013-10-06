# quick'n'dirty fixture loader
def load_fixture(path)
  Pathname.new('spec/fixtures').join(path).expand_path.read
end
