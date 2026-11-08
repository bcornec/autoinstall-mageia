                # 500MB /boot spaces
                 {
                        'fs_type' => 'ext4',
                        'mntpoint' => '/boot',
                        'size' => 1003808,
                        'hd' => 'sdb',
                 },
                # 4 GB swap spaces
                 {
                        'fs_type' => 'swap',
                        'size' => 8038086,
                        'hd' => 'sdb',
                 },
                # 15 GB /
                 {
                        'fs_type' => 'ext4',
                        'mntpoint' => '/',
                        'size' => 30165190,
            		'hd' => 'sdb',
                },
                # 10 GB mini /home
                 {
                        'fs_type' => 'ext4',
                        'mntpoint' => '/home',
                        'size' => 20283384,
            		'hd' => 'sdb',
                        'ratio' => 100,
                },
