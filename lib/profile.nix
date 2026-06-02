{
  hostName,
  isLaptop ? false,
  hasNvidia ? false,
  isVM ? false,
  useDisko ? true,
  user ? "josh",
}:
{
  inherit hostName isLaptop hasNvidia isVM useDisko user;
  isDesktop = !isLaptop;
}
