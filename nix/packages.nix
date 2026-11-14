{
  desktop = pkgs:
    with pkgs; [
      quickshell
      xwayland-satellite
      matugen
      cliphist
      wl-clipboard
      wtype
      libqalculate
      playerctl
      brightnessctl
      imagemagick
      realesrgan-ncnn-vulkan
      libnotify
      curl
      dconf
      nautilus
      ffmpegthumbnailer
      adw-gtk3
      adwaita-icon-theme
      material-symbols
      nerd-fonts.agave
    ];

  terminal = pkgs:
    with pkgs; [
      kitty
      fish
      starship
      tmux
      neovim
      lazygit
      fastfetch
      git
      eza
      bat
      btop
      ripgrep
      fd
      fzf
      imagemagick
      ghostscript
      nerd-fonts.agave
    ];
}
