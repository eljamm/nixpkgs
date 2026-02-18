{
  runTest,
  runTestOn,
}:
{
  basic = runTestOn [ "x86_64-linux" ] ./basic;
  plugins-livechat = runTest ./plugins-livechat;
}
