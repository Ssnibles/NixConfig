{
  hostName,
  isLaptop ? false,
  hasNvidia ? false,
  isVM ? false,
  useDisko ? true,
  hasPrinting ? false,
  user ? "josh",
}:
{
  inherit hostName isLaptop hasNvidia isVM useDisko hasPrinting user;
  isDesktop = !isLaptop;
}
