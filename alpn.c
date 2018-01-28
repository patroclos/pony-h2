#include <openssl/ssl.h>
#include <stdio.h>
#include <string.h>

int proto_cb(SSL *ssl,
             const unsigned char **out,
             unsigned char *outlen,
             const unsigned char *in,
             unsigned int inlen,
             void *arg)
{
  void **args = (void**) arg;
  size_t num_supported = *(size_t *)args[1];
  const unsigned char **supported = (const unsigned char**)args[0];

  for (unsigned i = 0; i < inlen;)
  {
    unsigned char protolen = in[i++];
    const unsigned char *proto = in + i;

    for (size_t isup = 0; isup < num_supported; isup++)
    {
      if (memcmp(supported[isup], proto, protolen) == 0)
      {
        //printf("PROTO MATCH: %.*s\n", protolen, proto);
        *out = proto;
        *outlen = protolen;
        return SSL_TLSEXT_ERR_OK;
      }
    }
  }

  return SSL_TLSEXT_ERR_ALERT_FATAL;
}

void server_use_protos(SSL_CTX *ctx, const unsigned char **protos, const size_t len)
{
  void **args = malloc(sizeof(void *) * 2);
  size_t *_len = malloc(sizeof(size_t *));
  *_len = len;
  args[0] = protos;
  args[1] = _len;

  //printf("**DEBUG** Setting SSL alpn callback for ssl=%p\n", ctx);
  SSL_CTX_set_alpn_select_cb(ctx, proto_cb, args);
}
