package com.chatterbox.controller;

import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.Base64;

@RestController
@RequestMapping("/api/v1/proxy")
public class ImageProxyController {

    private final RestTemplate restTemplate;

    public ImageProxyController() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * Proxies Google profile images to avoid CORS and rate limiting issues
     * Usage: /api/v1/proxy/image?url=base64EncodedUrl
     */
    @GetMapping("/image")
    public ResponseEntity<byte[]> proxyImage(@RequestParam String url) {
        try {
            // Decode the base64 URL
            String imageUrl = new String(Base64.getDecoder().decode(url));

            System.out.println("🖼️ Proxying image: " + imageUrl);

            // Create request entity with headers
            HttpHeaders requestHeaders = new HttpHeaders();
            requestHeaders.set("User-Agent", "Mozilla/5.0");
            HttpEntity<String> entity = new HttpEntity<>(requestHeaders);

            // Fetch the image from Google
            ResponseEntity<byte[]> response = restTemplate.exchange(
                    imageUrl,
                    HttpMethod.GET,
                    entity,
                    byte[].class);

            if (response.getBody() == null || response.getBody().length == 0) {
                System.err.println("❌ Empty response body");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }

            // Return the image with proper headers and caching
            HttpHeaders headers = new HttpHeaders();

            // Use the content type from Google's response, or default to image/jpeg
            MediaType contentType = response.getHeaders().getContentType();
            if (contentType != null) {
                headers.setContentType(contentType);
            } else {
                headers.setContentType(MediaType.IMAGE_JPEG);
            }

            // Cache for 1 hour to reduce requests to Google
            headers.setCacheControl(CacheControl.maxAge(3600, java.util.concurrent.TimeUnit.SECONDS));
            headers.add("Access-Control-Allow-Origin", "*");

            System.out.println("✅ Successfully proxied image (" + response.getBody().length + " bytes)");

            return new ResponseEntity<>(response.getBody(), headers, HttpStatus.OK);

        } catch (Exception e) {
            System.err.println("❌ Failed to proxy image: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }
}
