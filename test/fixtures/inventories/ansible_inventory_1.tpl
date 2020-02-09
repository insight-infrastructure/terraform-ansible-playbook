[${hostname_1}-0]
${host_ip_1}

[${hostname_1}-0:vars]
${hostname_1_vars}

[${hostname_1}:children]
${hostname_1}-0

[${hostname_2}]
${host_ip_2}

[${hostname_3}]
${host_ip_3}

