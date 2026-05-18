# AWS CloudFront - Dokumentasi Lengkap

## Daftar Isi
1. [Pengenalan CloudFront](#pengenalan-cloudfront)
2. [Konsep Dasar](#konsep-dasar)
3. [Fitur Utama](#fitur-utama)
4. [Arsitektur dan Cara Kerja](#arsitektur-dan-cara-kerja)
5. [Konfigurasi CloudFront](#konfigurasi-cloudfront)
6. [Origins dan Distributions](#origins-dan-distributions)
7. [Caching Strategy](#caching-strategy)
8. [Security](#security)
9. [Performance Optimization](#performance-optimization)
10. [Monitoring dan Logging](#monitoring-dan-logging)
11. [Best Practices](#best-practices)
12. [Troubleshooting](#troubleshooting)
13. [Pricing](#pricing)

---

## Pengenalan CloudFront

### Apa itu CloudFront?
AWS CloudFront adalah Content Delivery Network (CDN) global yang mempercepat distribusi konten kepada pengguna dengan latensi rendah. CloudFront bekerja dengan mengumpulkan konten dari origin server dan mendistribusikannya melalui jaringan edge locations yang tersebar di seluruh dunia.

### Mengapa Menggunakan CloudFront?
- **Kecepatan**: Mengurangi latency dengan cache di lokasi terdekat pengguna
- **Keamanan**: DDoS protection, SSL/TLS encryption, dan Web Application Firewall (WAF)
- **Skalabilitas**: Menangani traffic spike tanpa perlu provisioning manual
- **Cost Effective**: Mengurangi bandwidth dari origin server
- **Global Reach**: 500+ edge locations di 90+ negara
- **Integrasi AWS**: Seamless integration dengan S3, ELB, EC2, dan layanan AWS lainnya

---

## Konsep Dasar

### 1. Origin
Origin adalah source data/konten utama yang akan didistribusikan oleh CloudFront. Tipe origin:
- **S3 Bucket**: Untuk hosting static content
- **Custom Origin**: HTTP/HTTPS endpoint (EC2, load balancer, web server)
- **Mediastore Container**: Untuk media streaming
- **Lambda Function URL**: Untuk dynamic content

### 2. Edge Location
Data center AWS yang tersebar di seluruh dunia. Ada 500+ edge locations yang merupakan cache servers terdekat dengan pengguna.

### 3. Regional Edge Cache
Cache yang lebih besar di tingkat regional. Memiliki cache lifetime lebih lama dibanding edge locations biasa.

### 4. Distribution
Konfigurasi yang menghubungkan origin dengan edge locations. Menentukan bagaimana konten didistribusikan dan di-cache.

### 5. Cache Hit Ratio
Persentase request yang dilayani dari cache vs dari origin. Target minimal 90%.

---

## Fitur Utama

### 1. Content Caching
- Automatic caching berdasarkan TTL (Time To Live)
- Customizable cache headers
- Query string handling
- Cookie-based caching

### 2. Protocol Support
- HTTP/1.1, HTTP/2, HTTP/3
- WebSocket support
- TLS 1.0 - 1.3

### 3. Compression
- Automatic gzip compression
- Brotli compression support
- Mengurangi payload hingga 70%

### 4. SSL/TLS
- Free SSL certificate
- Custom SSL certificate support
- Automatic certificate renewal
- TLS 1.2 minimum recommended

### 5. Access Control
- Origin Access Identity (OAI) - deprecated
- Origin Access Control (OAC) - recommended
- Signed URLs dan Signed Cookies
- Private content distribution
- Geographic restrictions

### 6. DDoS Protection
- AWS Shield Standard (included)
- AWS Shield Advanced (paid)
- Automatic scaling untuk handle attack

### 7. Integration
- AWS Lambda@Edge untuk processing di edge
- CloudWatch untuk monitoring
- CloudTrail untuk audit logging
- AWS WAF untuk application layer protection

---

## Arsitektur dan Cara Kerja

### Flow Diagram
```
User Request
     ↓
Edge Location (terdekat)
     ├─ Cache HIT → Serve from cache
     └─ Cache MISS → Request to Regional Edge Cache
                        ├─ Cache HIT → Serve from cache
                        └─ Cache MISS → Request to Origin
```

### Proses Request Step by Step

1. **User mengirim request** ke domain CloudFront
2. **Route ke Edge Location** terdekat (DNS routing)
3. **Edge Location** check cache
   - Jika ada dan belum expired → Return content
   - Jika tidak atau expired → Continue ke step 4
4. **Request ke Regional Edge Cache**
   - Check cache
   - Jika cache HIT → Return ke edge location
   - Jika cache MISS → Continue ke step 5
5. **Request ke Origin Server**
   - Origin mengirim response dengan cache headers
   - Response kembali ke edge location
6. **Cache di Edge Location** sesuai TTL
7. **Cache di Regional Edge Cache** sesuai TTL
8. **Response dikirim ke user**

---

## Konfigurasi CloudFront

### Membuat Distribution

#### Step 1: Choose Origin Settings
```
Distribution Type:
- Web Distribution (untuk HTTP/HTTPS)
- RTMP Distribution (deprecated)

Origin Domain:
- S3 bucket: mybucket.s3.amazonaws.com
- Custom: example.com
- ALB: myalb-123456.us-east-1.elb.amazonaws.com

Origin Path: /production (optional)
```

#### Step 2: Cache Behavior Settings
```
Path Pattern: /api/* | /static/*
Allowed HTTP Methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
Cache Policy:
  - Managed Cache Policy
  - Custom Cache Policy
```

#### Step 3: Function Associations
```
CloudFront Functions:
  - Viewer Request
  - Viewer Response
  
Lambda@Edge:
  - Viewer Request
  - Origin Request
  - Origin Response
  - Viewer Response
```

#### Step 4: Distribution Settings
```
Web ACL: (AWS WAF)
Price Class: All Locations | 100 | 200
HTTP/HTTPS: Redirect HTTP to HTTPS recommended
Default Root Object: index.html
Enable IPv6: Yes/No
```

### Contoh Konfigurasi untuk S3
```
Origin Domain: mybucket.s3.us-east-1.amazonaws.com
Origin Access Control: Create OAC
Viewer Protocol Policy: Redirect HTTP to HTTPS
Cache Policy: CachingOptimized
Compress Objects Automatically: Yes
Allowed HTTP Methods: GET, HEAD
```

---

## Origins dan Distributions

### Single Origin Distribution
```
Distribution
    └── Origin (S3 or Custom)
```

### Multi-Origin Distribution
```
Distribution
    ├── Origin 1: S3 (static content)
    ├── Origin 2: API Gateway (dynamic)
    ├── Origin 3: Lambda Function URL
    └── Multiple Cache Behaviors untuk routing
```

### Contoh Multi-Origin Configuration
```yaml
Origins:
  - S3Origin:
      DomainName: mybucket.s3.amazonaws.com
      S3OriginConfig:
        OriginAccessIdentity: origin-access-identity/cloudfront/ABCDEFG
  
  - APIOrigin:
      DomainName: api.example.com
      CustomOriginConfig:
        HTTPPort: 80
        OriginProtocolPolicy: http-only

CacheBehaviors:
  - PathPattern: /api/*
    TargetOriginId: APIOrigin
    ViewerProtocolPolicy: https-only
    CachePolicy: AWS_Managed_CachingDisabled
  
  - PathPattern: /static/*
    TargetOriginId: S3Origin
    ViewerProtocolPolicy: allow-all
    CachePolicy: AWS_Managed_CachingOptimized

DefaultCacheBehavior:
  TargetOriginId: S3Origin
  ViewerProtocolPolicy: redirect-to-https
  CachePolicy: AWS_Managed_CachingOptimized
```

---

## Caching Strategy

### Cache Policy Terdapat Tiga Komponen:

#### 1. TTL (Time To Live)
```
Minimum TTL: 0 detik (dapat di-override jika cache-control > minimum)
Maximum TTL: Default 31536000 (1 tahun)
Default TTL: Berdasarkan cache-control header

Contoh:
- Static assets (CSS, JS): 3600-86400 detik (1-24 jam)
- Images: 86400 detik (1 hari)
- HTML: 3600 detik atau less (1 jam)
- API responses: 0 (no cache)
```

#### 2. Query String Handling
```
None: Ignore query strings (cache-key tidak include query string)
Whitelist: Include specific query string parameters
All: Include all query string parameters
```

#### 3. Header Handling
```
None: Ignore headers
Whitelist: Specific headers (Authorization, Host, User-Agent)
```

### AWS Managed Cache Policies

```
1. CachingOptimized
   - Default TTL: 86400 (1 hari)
   - Max TTL: 31536000 (1 tahun)
   - Query strings: None
   - Headers: None
   - Untuk: Static content

2. CachingDisabled
   - Default TTL: 0
   - Setiap request ke origin
   - Untuk: Dynamic content, API

3. Amplify
   - Custom managed policy
   - Untuk: Amplify applications

4. APIGateway_CachingOptimized
   - Optimized untuk API Gateway
```

### Custom Cache Policy Best Practices
```
API Endpoints:
  - Query String: All (untuk filter/pagination)
  - Headers: Origin, Authorization
  - Cache: Disable atau very short TTL

User Profile Pages:
  - Query String: None
  - Headers: Authorization
  - Cache: Disable

Static Assets (CSS, JS, Images):
  - Query String: None
  - Headers: None
  - Cache: Maximum (1 tahun+)

Homepage:
  - Query String: None
  - Headers: None
  - Cache: Short (1 jam)
```

### Cache Invalidation
```
Manual Invalidation:
  - Gunakan wildcard: /*
  - Specific path: /api/users/* atau /images/logo.png
  - Cost: Pertama 3000/bulan gratis, setelahnya $0.005/path

Best Practice:
  - Gunakan versioned assets (v1.css -> v2.css)
  - Query string untuk versioning (?v=2)
  - Hindari invalidation manual
```

---

## Security

### 1. SSL/TLS Configuration

```
Viewer Protocol Policy:
- allow-all: HTTP dan HTTPS
- redirect-to-https: HTTP redirect ke HTTPS
- https-only: Hanya HTTPS

Minimum TLS Version:
- TLSv1.2_2021: Recommended
- TLSv1_2016 atau lebih lama: Legacy support

Certificate:
- Default: *.cloudfront.net (included)
- Custom: Upload atau request dari ACM
```

### 2. Origin Access Control (OAC)
Recommended approach untuk S3:

```
Benefits:
- Supports all S3 regions
- Sign requests dengan AWS Signature Version 4
- S3 bucket policy untuk restrict access

Setup:
1. Create OAC di CloudFront
2. S3 bucket policy automatically updated
3. Only CloudFront bisa access S3

Bucket Policy Example:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::mybucket/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/ABCDEFG"
        }
      }
    }
  ]
}
```

### 3. Signed URLs dan Cookies

#### Signed URLs
```
Gunakan untuk:
- Private video distribution
- Time-limited access
- Single file access

Keuntungan:
- Mudah debug (bisa test di browser)
- Unique per request
- Dapat expired

Contoh:
https://d123456.cloudfront.net/video.mp4?Expires=1234567890&Signature=AbCdEf...

How to generate (SDK):
- AWS SDK untuk CloudFront Signer
- Generate ekspired timestamp
- Sign dengan private key
```

#### Signed Cookies
```
Gunakan untuk:
- Multiple file access
- Legacy browsers (HTTP only)
- Complex access patterns

Keuntungan:
- Covers multiple files
- Cookie-based authentication
- Transparent untuk user

Process:
1. User authenticate
2. Server generate signed cookie
3. Browser attach cookie ke all requests
4. CloudFront validate cookie
```

### 4. AWS WAF Integration
```
Fitur:
- Rate limiting
- IP reputation list
- SQL injection protection
- Cross-site scripting (XSS) protection
- Geo-blocking

Setup:
1. Create WAF Web ACL
2. Attach ke CloudFront distribution
3. Define rules

Contoh Rules:
- Rate-based: Max 2000 requests per 5 min
- IP set: Block specific IPs
- Geo: Allow only specific countries
- SQL injection: Managed rule
```

### 5. DDoS Protection
```
AWS Shield Standard (included):
- Automatic protection
- Layer 3 dan 4

AWS Shield Advanced (opsional):
- Layer 7 protection
- 24/7 DDoS Response Team
- DDoS cost protection

Best Practice:
- Enable Shield Advanced untuk critical
- Combine dengan WAF
- Monitor dengan CloudWatch
```

---

## Performance Optimization

### 1. Compression
```
Enable gzip/brotli:
- Automatic compress Object Types (HTML, CSS, JS)
- Custom Compress Object Types untuk text files

Impact:
- JSON: 70-80% reduction
- HTML: 60-70% reduction
- JavaScript: 60-70% reduction
- Images: 10-15% reduction (sudah compressed)

Automatic Compression:
- Enabled by default untuk managed policies
- Supported on all edge locations
```

### 2. HTTP/2 dan HTTP/3
```
HTTP/2:
- Multiplexing requests
- Header compression
- Server push

HTTP/3:
- QUIC protocol
- Lower latency
- Better mobile performance

Enable:
- Already enabled by default
- Supported pada all edge locations
```

### 3. Edge Functions dan Lambda@Edge

#### CloudFront Functions
```
Use case:
- Viewer Request
- Simple transformations
- URL rewriting
- Cache key modification

Advantages:
- 1ms start time
- Sub millisecond execution
- 128MB memory (fixed)

Example:
function handler(event) {
    var request = event.request;
    request.headers["x-custom-header"] = { value: "custom" };
    return request;
}
```

#### Lambda@Edge
```
Use case:
- Complex logic
- Dynamic content generation
- Real-time personalization

Trigger Points:
1. Viewer Request: Before routing
2. Origin Request: Before contacting origin
3. Origin Response: After receiving from origin
4. Viewer Response: Before sending to viewer

Memory: Up to 3008 MB
Timeout: 5 seconds (30 for origin response)

Example:
exports.handler = (event, context, callback) => {
    const request = event.Records[0].cf.request;
    if (!request.headers.authorization) {
        return {
            status: '401',
            statusDescription: 'Unauthorized'
        };
    }
    callback(null, request);
};
```

### 4. Cache Key Optimization
```
Best Practice:
- Minimize query string inclusion
- Remove unnecessary headers
- Use consistent URL structure

Example:
/images/product-123.jpg (good)
/product/images/123?ver=1&size=large&optimize=true (bad)

Versioning strategy:
- /css/style.v2.css (immutable)
- /js/app.v3.js

Avoids:
- Session IDs
- Tracking parameters
- Unnecessary cookies
```

### 5. Origin Shield
```
Optional caching layer antara edge locations dan origin.

Benefits:
- Reduced origin load
- Better cache ratio (80-90% vs 60-70%)
- Origin failure resilience

Cost:
- $0.01 per GB (in addition ke data transfer)
- Worth untuk high traffic

Use Cases:
- High traffic sites
- Origin dengan limited capacity
- Backend services
```

---

## Monitoring dan Logging

### 1. CloudWatch Metrics
```
Default Metrics (included):
- Requests: Total requests
- BytesDownloaded: Data sent to viewers
- BytesUploaded: Data from origin
- 4xxErrorRate: 4xx errors percentage
- 5xxErrorRate: 5xx errors percentage
- ErrorRate: Total error rate

Standard Metrics (additional cost):
- OriginLatency
- CacheHitRate
- Distribution metrics per URL

Query:
STATS avg(BytesDownloaded), max(OriginLatency) by HTTPStatus
```

### 2. Access Logs
```
Enable logging:
1. Select target S3 bucket
2. Prefix: cloudfront-logs/
3. Logs dikirim setiap jam

Log format:
[date time x-edge-location bytes status origip user-agent referer]

Example:
2024-01-15 10:30:45 LAX89 1234 200 192.0.2.1 Mozilla/5.0 https://example.com/

Analysis:
- Athena untuk query logs
- CloudWatch Insights
- 3rd party tools (Splunk, etc)
```

### 3. Real-time Logs
```
Real-time streaming ke Kinesis.

Fields:
- timestamp
- c-source-port
- cs-method
- cs-host
- cs-uri-stem
- sc-status
- cs-user-agent

Use cases:
- Real-time monitoring
- Immediate alerts
- Custom analytics

Cost:
- $0.02 per 100,000 logs
```

### 4. CloudTrail Logging
```
Track API calls ke CloudFront.

Events logged:
- CreateDistribution
- UpdateDistribution
- DeleteDistribution
- CreateInvalidation

Location:
- S3 bucket
- 15 minutes delivery

Query CloudTrail:
- Athena
- CloudTrail Insights
```

### 5. Alarms & Notifications
```
Common Alarms:
- 4xx error rate > 5%
- 5xx error rate > 1%
- Origin latency > 500ms
- Cache hit rate < 80%

Setup SNS notifications:
- Email
- SMS
- Lambda
- HTTP endpoint
```

---

## Best Practices

### 1. Cache Strategy
```
✓ DO:
- Versioning assets (..v2.css)
- Use CloudFront TTL, not S3 versioning
- Separate static dan dynamic
- Cache aggressively untuk static
- Cache minimally untuk dynamic

✗ DON'T:
- Disable caching untuk performance
- Use session IDs di cache key
- Ignore cache-control headers
- Manual invalidation untuk setiap update
```

### 2. Security
```
✓ DO:
- Require HTTPS (redirect-to-https)
- Use OAC untuk S3 access
- Enable WAF untuk web apps
- Signed URLs untuk private content
- Minimal TLS 1.2

✗ DON'T:
- Allow HTTP untuk sensitive data
- Expose origin servers
- Cache sensitive data
- Use HTTP di origin
```

### 3. Cost Optimization
```
✓ DO:
- Monitor data transfer
- Use Origin Shield untuk high CPU load
- Increase cache hit ratio
- Compress content
- Use reserved capacity (commitment)

✗ DON'T:
- Unnecessary regional edge caches
- Excessive invalidations
- Poor cache configuration
- Forget to monitor ACM renewal
```

### 4. Origin Configuration
```
✓ DO:
- Keep-Alive connections
- Gzip compression di origin
- Proper cache headers
- Health checks untuk EC2
- Connection timeout: 10 seconds

✗ DON'T:
- Origin di same region (move to different region)
- Custom 404 handling di origin
- Serve stale content
- Long timeouts
```

### 5. Performance
```
✓ DO:
- Enable compression
- Use HTTP/2
- Minimize cache misses
- Optimize image sizes
- Use CloudFront Functions

✗ DON'T:
- Large HTML files
- Unoptimized images
- Excessive redirects (increase latency)
- Complex Lambda functions
```

---

## Troubleshooting

### 1. High 4xx/5xx Errors
```
Diagnosis:
- Check access logs
- Verify origin health
- Check cache behavior rules
- Validate Origin Access Control

Common Causes:
- 403 Forbidden: OAC misconfigured
- 404 Not Found: Wrong origin path
- 502 Bad Gateway: Origin down
- 504 Gateway Timeout: Slow origin

Solution:
- Fix origin issue
- Review cache behavior
- Check security groups
- Increase origin timeout
```

### 2. Low Cache Hit Ratio
```
Target: 90%+ cache hit ratio

Diagnosis:
- Check query string handling
- Verify TTL settings
- Analyze access logs

Common Causes:
- Query strings dalam cache key
- Short TTL
- Headers dalam cache key
- Too many unique URLs

Solution:
- Whitelist query strings
- Increase TTL
- Remove unnecessary headers
- Use consistent URL structure
```

### 3. Slow Performance
```
Diagnosis:
- Check edge location latency
- Monitor origin latency
- Verify compression

Common Causes:
- Far edge location
- Slow origin
- Uncompressed content
- Large files

Solution:
- Check user location
- Optimize origin
- Enable compression
- Reduce file sizes
- Use Origin Shield
```

### 4. SSL/TLS Certificate Issues
```
Common: Certificate mismatch, expired certificate

Solution:
- Verify domain dalam certificate
- Check ACM certificate status
- Ensure certificate valid untuk domain
- Minimal TLS version check
```

### 5. Origin Shield Not Working
```
Symptoms:
- Cache hit ratio tidak meningkat
- Origin latency masih tinggi

Solution:
- Verify enabled
- Check region (same as origin region recommended)
- Monitor CloudWatch metrics
- Ensure TTL > 1 menit
```

### 6. Function Execution Errors
```
CloudFront Functions:
- Check logs di CloudWatch
- Verify syntax
- Check execution time (< 1ms)

Lambda@Edge:
- CloudWatch Logs (region: us-east-1)
- Check memory usage
- Verify timeout
- Check IAM role
```

---

## Testing dan Validation

### 1. Cache Testing
```bash
# Test cache hit
curl -I https://d123456.cloudfront.net/static/style.css

Headers to check:
- X-Cache: Hit from cloudfront (cache hit)
- X-Cache: RefreshHit from cloudfront (revalidation)
- X-Cache: Miss from cloudfront (cache miss)
- Age: Seconds in cache
```

### 2. SSL Testing
```bash
# Test SSL configuration
curl -I --tlsv1.2 https://d123456.cloudfront.net/

# Dengan specific ciphers
openssl s_client -connect d123456.cloudfront.net:443
```

### 3. Performance Testing
```
Tools:
- WebPageTest (webpagetest.org)
- GTmetrix
- Lighthouse
- Apache Bench (ab)

Load test origin:
ab -n 1000 -c 10 https://d123456.cloudfront.net/
```

---

## Pricing

### Data Transfer Out
```
Pricing berdasarkan region dan volume:

Americas:
- $0.085 per GB (first 10 TB/month)
- $0.080 per GB ($10-40 TB/month)
- $0.060 per GB (40+ TB/month)

Europe:
- $0.085 per GB (first 10 TB/month)
- $0.080 per GB ($10-40 TB/month)
- $0.055 per GB (40+ TB/month)

Asia Pacific (lower):
- $0.120 per GB

Asia Pacific (higher):
- $0.170 per GB

Gratis dari AWS:
- Transfer ke EC2, ELB, etc di same region
```

### Request Pricing
```
HTTP/HTTPS Requests:
- $0.0075 per 10,000 requests (US, Europe)
- $0.0100 per 10,000 requests (other region)

Field Level Encryption:
- $0.02 per 10,000 requests
```

### Optional Services
```
- Invalidation: Pertama 3000/month gratis, $0.005/path
- Origin Shield: $0.01 per GB
- Dedicated IP: $600/month
- Lambda@Edge: $0.60 per 1M requests + compute time
- CloudFront Functions: Free (3M included)
```

### Cost Estimation Example
```
Scenario: 50 TB/month, 500M requests, US region

Data Transfer: 50 TB = 51,200 GB
- First 10 TB: 10,240 × $0.085 = $870
- 10-40 TB: 30,720 × $0.080 = $2,458
- 40-50 TB: 10,240 × $0.060 = $614
Total transfer: $3,942

Requests: 500M = 50,000 × $0.0075 = $375

Total: ~$4,317/month
```

### Saving Tips
```
1. Compression: Reduce 70% data transfer
2. Cache optimization: 99% cache hit
3. Reserved capacity: Up to 30% discount
4. AWS Savings Plan: Additional 10-30%
```

---

## Integration dengan AWS Services

### 1. S3 Integration
```
Best untuk: Static content, website hosting

Setup:
1. Create S3 bucket
2. Create CloudFront distribution
3. Set S3 bucket as origin
4. Enable OAC
5. Update bucket policy

S3 Bucket Policy Update (Automatic dengan OAC):
{
  "Effect": "Allow",
  "Principal": {
    "Service": "cloudfront.amazonaws.com"
  },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::bucket/*"
}
```

### 2. API Gateway Integration
```
Best untuk: RESTful APIs, microservices

Setup:
1. Create API Gateway
2. Create CloudFront distribution
3. Set API Gateway endpoint as origin
4. Disable cache untuk GET /api/*
5. Add API key handling

Cache Behavior:
PathPattern: /api/*
CachePolicy: CachingDisabled
OriginRequestPolicy: AllViewerAndWhitelistCloudFrontHeaders
```

### 3. Lambda@Edge Integration
```
Use cases:
- Authentication
- URL rewriting
- Custom headers
- Content transformation

Example: URL rewriting
exports.handler = (event, context, callback) => {
    let request = event.Records[0].cf.request;
    
    if (request.uri === '/') {
        request.uri = '/index.html';
    }
    
    callback(null, request);
};
```

### 4. Lambda Function URL
```
Best untuk: Serverless API

Setup:
1. Create Lambda function
2. Create Function URL
3. Set sebagai origin di CloudFront
4. Configure cache behavior

Benefits:
- No API Gateway overhead
- Direct Lambda invocation
- Lower latency
```

### 5. Application Load Balancer
```
Best untuk: Traditional applications

Setup:
1. Create ALB
2. Create CloudFront distribution
3. Set ALB as origin
4. Enable health checks

Configuration:
- HTTP/HTTPS ke ALB
- Path-based routing untuk multiple services
- Sticky sessions jika diperlukan
```

---

## Troubleshooting Checklist

### Sebelum Production Launch:
```
□ Test distribution dengan berbagai lokasi
□ Verify SSL certificate
□ Test cache hit ratio
□ Check origin connectivity
□ Validate security groups
□ Test Origin Access Control
□ Verify CloudFront domain atau custom domain
□ Load test
□ Test invalidation procedure
□ Document edge cases
```

### Ongoing Monitoring:
```
□ Monitor error rates daily
□ Check cache hit ratio weekly
□ Review CloudWatch metrics
□ Analyze access logs
□ Update SSL certificates
□ Review security groups
□ Test disaster recovery
□ Performance benchmarking
```

---

## Referensi Penting

### Dokumentasi Resmi
- AWS CloudFront Developer Guide
- CloudFront API Reference
- CloudFront Best Practices

### Tools & Services
- AWS CloudFront Console
- AWS CLI (cloudfront commands)
- AWS SDK (boto3 untuk Python)
- CloudFront Testing Tools

### Monitoring
- CloudWatch Dashboard
- AWS CloudTrail
- CloudFront Access Logs
- Real-time Logs dengan Kinesis

---

## Kesimpulan

AWS CloudFront adalah layanan CDN yang powerful untuk meningkatkan performance, keamanan, dan scalability aplikasi web. Dengan pemahaman mendalam tentang caching strategy, security configuration, dan best practices, Anda dapat mengoptimalkan infrastruktur global dengan mudah.

**Key Takeaways:**
1. Cache strategy adalah kunci untuk performa
2. Security harus menjadi prioritas (HTTPS, wAF, OAC)
3. Monitor metrics untuk optimization berkelanjutan
4. Integrate dengan AWS services untuk solusi komprehensif
5. Gunakan tools seperti Lambda@Edge untuk kustomisasi advanced

---

**Last Updated**: May 18, 2026
**Version**: 1.0