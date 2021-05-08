require 'package'

class Py3_snowballstemmer < Package
  description 'snowballstemmer provides 29 stemmers for 28 languages generated from Snowball algorithms.'
  homepage 'https://snowballstem.org/'
  @_ver = '2.1.0'
  version @_ver
  license 'BSD-3'
  compatibility 'all'
  source_url 'https://github.com/snowballstem/snowball.git'
  git_hashtag 'v' + @_ver

  depends_on 'py3_setuptools' => :build

  def self.build
    system "python3 setup.py build #{PY3_SETUP_BUILD_OPTIONS}"
  end

  def self.install
    system "python3 setup.py install #{PY_SETUP_INSTALL_OPTIONS}"
  end
end
