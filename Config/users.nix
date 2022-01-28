{
  users = {
    admin = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = "***********";
      description = "Administrateur";
    };
    visiteur = {
      uid = 1001;
      isNormalUser = true;
      # temporaire
      hashedPassword = "$6$x1gFqnYIw9HbkRbq$U0zMVqyCkMh3npktqSsufA6VESUmY5aZCDngA1T05zM9u82f4ceb/otws/ZXTg05rW/gGYsPgAyQAEhZds8Ki.";
      description = "Visiteur";
    };
  };
}
