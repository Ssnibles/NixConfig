{
  hostName,
  isLaptop ? false,
  hasNvidia ? false,
  useDisko ? true,
  hasPrinting ? false,
  user ? "josh",
}:
{
  inherit hostName isLaptop hasNvidia useDisko hasPrinting user;
  isDesktop = !isLaptop;
}
