node 'locustmaster' {
  include locustserver
}
node /a-node*/ {
  include locustclient
}
node /^ip-.*\.compute.internal/ {
  include locustclient
}
