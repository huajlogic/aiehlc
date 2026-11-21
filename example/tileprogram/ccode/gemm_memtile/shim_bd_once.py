# Hand edit (last): shim BDs and OOO channel config are identical on every launch -- write
# them on the first launch only; later launches only re-push the start queues.
# usage: shim_bd_once.py <aout/worklocal>
import re, sys
wl = sys.argv[1]
s = open(wl + '/host.cc').read()
i = s.index('void host_canonicalized(XAie_DevInst* v1, void* v2, void* v3, void* v4) {')
e = s.index('  return;\n}', i)
body = s[i:e]
body = re.sub(r'= (__Runtime_dma_bd_config(?:_multidim_ooo|_multidim)?\()', r'= g_bd_once ? XAie_DmaDesc() : \1', body)
body = re.sub(r'(\n\s*)(__Runtime_dma_channel_enable_ooo\([^;]*;)', r'\1if (!g_bd_once) \2', body)
s = s[:i] + body + '  g_bd_once = 1;\n' + s[e:]
s = s.replace('void host_canonicalized(XAie_DevInst* v1, void* v2, void* v3, void* v4) {',
              'static int g_bd_once;\nvoid host_canonicalized(XAie_DevInst* v1, void* v2, void* v3, void* v4) {', 1)
open(wl + '/host.cc', 'w').write(s)
print('shim BDs written once')
