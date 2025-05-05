                # 500MB /boot spaces
                 {
                        'fs_type' => 'ext4',
                        'mntpoint' => '/boot',
                        # 200 MB
                        'size' => 403808,
                        'hd' => 'sda',
                 },
                # 4 GB swap spaces
                 {
                        'fs_type' => 'swap',
                        'size' => 8038086,
                        'hd' => 'sda',
                 },
                # 15 GB /
                 {
                        'fs_type' => 'ext4',
                        'mntpoint' => '/',
                        'size' => 30165190,
            			'hd' => 'sda',
                },
                # 10 GB mini /home
                 {
                        'fs_type' => 'ext4',
                        'mntpoint' => '/home',
                        'size' => 20283384,
            			'hd' => 'sda',
                        'ratio' => 100,
                },
