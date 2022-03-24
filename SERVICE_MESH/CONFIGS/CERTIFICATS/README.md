# Generate certificats
<pre>
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=Lab OSSM APIM Inc./CN=opentlc.com' -keyout lab-ossm-apim.com.key -out lab-ossm-apim.com.crt

openssl req -out httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout httpbin.example.com.key -subj "/CN=*.opentlc.com/O=LAB OSSM organization"

openssl x509 -req -days 365 -CA lab-ossm-apim.com.crt -CAkey lab-ossm-apim.com.key -set_serial 0 -in httpbin.example.com.csr -out httpbin.example.com.crt
</pre>