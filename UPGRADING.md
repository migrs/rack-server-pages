# Upgrading

## 0.2.x to 0.3.0

### Static-file caching changes by default

`static_etags` defaults to `true`. Static-file responses now include an ETag derived from a SHA-256 hash of the file contents. Matching `If-None-Match` validators return an empty `304` response for GET and HEAD. When both `If-None-Match` and `If-Modified-Since` are present, the ETag takes precedence: an old ETag produces a full response even if the file's timestamp is unchanged.

Requests with only `If-Modified-Since` retain Rack's timestamp-based conditional handling, including `304` responses for matching timestamps. Such requests still rely on accurate modification times; adopt content-versioned asset URLs for protection against deployment tools that preserve or normalize timestamps.

The file is read and hashed on each static request, adding disk and CPU work. To restore Rack's original static-file conditional handling without this content hashing, disable the option:

```ruby
use Rack::ServerPages do |config|
  config.static_etags = false
end
```

This omits content-based ETags and, with the default timestamp-validation setting, delegates conditional handling entirely to Rack. `static_cache_control` still applies when configured. Template responses and downstream applications are unaffected by this option.

### Optional timestamp-validation opt-out

`static_timestamps` defaults to `true`, preserving Rack's timestamp-only conditional responses. Set `config.static_timestamps = false` to ignore `If-Modified-Since` on static requests when modification times are unreliable. The `Last-Modified` response header is still emitted, and matching ETags can still produce a `304`. The switches are independent: set both `static_etags` and `static_timestamps` to `false` to disable both conditional checks. Neither option affects template responses or downstream applications.
