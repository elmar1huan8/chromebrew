require 'package'

class Transmission < Package
  description 'A fast, easy, and free BitTorrent client.'
  homepage 'https://transmissionbt.com/'
  version '4.0.2'
  license 'GPL-2, GPL-3 or Transmission-OpenSSL-exception, GPL-2 and MIT'
  compatibility 'x86_64 aarch64 armv7l'
  source_url 'https://github.com/transmission/transmission/releases/download/4.0.2/transmission-4.0.2.tar.xz'
  source_sha256 '39bf7a104a722805a9dc089cdaaffe33bf90b82230a7ea7f340cae59f00a2ee8'

  binary_url({
    aarch64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/transmission/4.0.2_armv7l/transmission-4.0.2-chromeos-armv7l.tar.zst',
     armv7l: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/transmission/4.0.2_armv7l/transmission-4.0.2-chromeos-armv7l.tar.zst',
     x86_64: 'https://gitlab.com/api/v4/projects/26210301/packages/generic/transmission/4.0.2_x86_64/transmission-4.0.2-chromeos-x86_64.tar.zst'
  })
  binary_sha256({
    aarch64: 'cf3fe4b1eee0677f3fbfcc275dc18eebcb9379c46c66e1f1edf0c067a92f9150',
     armv7l: 'cf3fe4b1eee0677f3fbfcc275dc18eebcb9379c46c66e1f1edf0c067a92f9150',
     x86_64: '250988507ff257b2815543dd9caafc7c1b3b7f3ab02aab275e7cef0f1bf088a6'
  })

  depends_on 'at_spi2_core' => :build
  depends_on 'cairomm_1_16' # R
  depends_on 'gcc' # R
  depends_on 'gdk_pixbuf' # R
  depends_on 'glibc' # R
  depends_on 'glibmm_2_68' # R
  depends_on 'glib' # R
  depends_on 'gnome_icon_theme' # L
  depends_on 'graphene' # R
  depends_on 'gtk4' # R
  depends_on 'gtkmm4' # R
  depends_on 'harfbuzz' # R
  depends_on 'hicolor_icon_theme' # L
  depends_on 'libcurl' # R
  depends_on 'libdeflate' # R
  depends_on 'libevent' # R
  depends_on 'libpsl' # R
  depends_on 'libsigcplusplus3' # R
  depends_on 'libutp' # L
  depends_on 'miniupnpc' # R
  depends_on 'openssl' # R
  depends_on 'pangomm_2_48' # R
  depends_on 'shared_mime_info'
  depends_on 'vulkan_headers' => :build
  depends_on 'vulkan_icd_loader' # R
  depends_on 'xdg_base' # L
  depends_on 'pango' # R

  def self.build
    system "cmake -B builddir -G Ninja \
      #{CREW_CMAKE_OPTIONS} \
      -DENABLE_CLI=ON \
      -DENABLE_GTK=ON \
      -DENABLE_UTILS=ON \
      -DINSTALL_LIB=ON \
      -DINSTALL_DOC=ON \
      -DUSE_GTK_VERSION=4"
    system "#{CREW_NINJA} -C builddir"
    starttransmission = <<~EOF
      #!/bin/bash
      TRAN=$(pidof transmission-daemon 2> /dev/null)
      if [ -z "$TRAN" ]; then
        #{CREW_PREFIX}/bin/transmission-daemon -c ~/Downloads -w ~/Downloads &
        sleep 3
      fi
      TRAN=$(pidof transmission-daemon 2> /dev/null)
      if [ -n "$TRAN" ]; then
        echo "transmission-daemon process $TRAN is running"
      else
        echo "transmission-daemon failed to start"
        exit 1
      fi
    EOF
    File.write('starttransmission', starttransmission)
    stoptransmission = <<~EOF
      #!/bin/bash
      TRAN=$(pidof transmission-daemon 2> /dev/null)
      if [ -n "$TRAN" ]; then
        sudo killall transmission-daemon
        sleep 3
      fi
      TRAN=$(pidof transmission-daemon 2> /dev/null)
      if [ -z "$TRAN" ]; then
        echo "transmission-daemon process stopped"
      else
        echo "transmission-daemon process $TRAN is running"
        exit 1
      fi
    EOF
    File.write('stoptransmission', stoptransmission)
    transmission = <<~EOF
      # Start the transmission daemon
      if [ -f #{CREW_PREFIX}/bin/starttransmission ]; then
        #{CREW_PREFIX}/bin/starttransmission
      fi
    EOF
    File.write('10-transmission', transmission)
  end

  def self.install
    system "DESTDIR=#{CREW_DEST_DIR} #{CREW_NINJA} -C builddir install"
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/bin"
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/etc/bash.d"
    FileUtils.install 'starttransmission', "#{CREW_DEST_PREFIX}/bin", mode: 0o755
    FileUtils.install 'stoptransmission', "#{CREW_DEST_PREFIX}/bin", mode: 0o755
    FileUtils.install '10-transmission', "#{CREW_DEST_PREFIX}/etc/bash.d", mode: 0o644
  end

  def self.postinstall
    puts "\nTo start the cli client, execute 'transmission-cli'".lightblue
    puts "\nTo start the gui client, execute 'transmission-gtk'".lightblue
    puts "\nTo start the daemon, execute 'starttransmission'".lightblue
    puts "\nTo stop the daemon, execute 'stoptransmission'".lightblue
    puts "\nTo finish the installation, execute 'source ~/.bashrc'".lightblue
    puts "\nConfiguration files are stored in #{HOME}/.config/transmission-daemon\n".lightblue
  end

  def self.preremove
    system 'stoptransmission'
  end

  def self.remove
    config_dirs_exist = false
    config_dirs = ["#{CREW_PREFIX}/.config/transmission", "#{CREW_PREFIX}/.config/transmission-daemon"]
    config_dirs.each do |config_dir|
      next unless Dir.exist? config_dir

      system "echo '#{config_dir}'; ls '#{config_dir}'"
      config_dirs_exist = true
    end
    if config_dirs_exist
      print "\nWould you like to remove the config directories above? [y/N] "
      case $stdin.gets.chomp.downcase
      when 'y', 'yes'
        config_dirs.each do |config_dir|
          FileUtils.rm_rf config_dir
          puts "#{config_dir} removed.".lightblue
        end
      else
        puts 'Directories saved.'.lightgreen
      end
    end
  end
end
