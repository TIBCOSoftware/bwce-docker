import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;
import java.net.URL;
import java.net.URLConnection;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.X509Certificate;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.xml.bind.DatatypeConverter;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/*
 * Copyright 2015 TIBCO Software Inc.
 * All rights reserved.
 *
 * This software is confidential and proprietary information of TIBCO Software Inc.
 *
 */

/**
 * @author <a href="mailto:vnalawad@tibco.com">Vijay Nalawade</a>
 *
 * @since 1.0.0
 */
public class ProfileTokenResolver {

    static String TOKEN_DELIMITER  = "#";
    static String pattern          = "\\" + TOKEN_DELIMITER + "([^" + TOKEN_DELIMITER + "]+)\\" + TOKEN_DELIMITER;
    static String PROFILE_ROOT_DIR = "/bwapp";

    public static void main(String[] args) throws Throwable {

        String disableSsl = System.getenv("DISABLE_SSL_VERIFICATION");
        if (Boolean.parseBoolean(disableSsl)) {
            disable_ssl_verification();
        }

        Map<String, String> tokenMap = new HashMap<String, String>();
        collectEnvVariables(tokenMap);
        collectPropertiesFromConsul(tokenMap);
        resolveTokens(tokenMap);
    }

    /**
     * This method collects value of ENV variables
     * 
     * @param valueMap
     */
    private static void collectEnvVariables(Map<String, String> valueMap) {
        Iterator<String> sysPropsItr = System.getenv().keySet().iterator();
        while (sysPropsItr.hasNext()) {
            String varName = sysPropsItr.next();
            valueMap.put(varName, System.getenv().get(varName));
        }
    }

    private static void collectPropertiesFromConsul(Map<String, String> valueMap) throws Exception {
        String profileName = System.getenv("APP_CONFIG_PROFILE_NAME");
        if (profileName == null) {
            profileName = "default";
        }
        String consulServerUri = System.getenv("CONSUL_SERVER_URI");

        if (consulServerUri == null) {
            if (isConsulServerConfigured()) {
                String consulPort = System.getenv("CONSUL_SERVER_PORT");
                if (consulPort == null) {
                    consulPort = "8500";
                }
                consulServerUri = "http://consulserver" + ":" + consulPort + "/v1/kv/" + profileName + "?recurse";
            }
        } else {
            if (!consulServerUri.endsWith("/")) {
                consulServerUri = consulServerUri + "/";
            }
            if (!consulServerUri.endsWith("v1/")) {
                consulServerUri = consulServerUri + "v1/";
            }
            consulServerUri = consulServerUri + "kv/" + profileName + "?recurse";
        }

        if (consulServerUri != null) {
            System.out.println("Loading Key/Value from Consul [" + consulServerUri + "]");
            try {
                ObjectMapper mapper = new ObjectMapper();
                URL springURL = new URL(consulServerUri);
                URLConnection connection = springURL.openConnection();
                connection.setReadTimeout(30000);
                connection.setConnectTimeout(30000);
                JsonNode response = mapper.readTree(connection.getInputStream());
                if (response.isArray()) {
                    for (int i = 0; i < response.size(); i++) {
                        JsonNode propNode = response.get(i);
                        String propName = propNode.get("Key").asText();
                        propName = propName.replace(profileName + "/", "");
                        if (!propName.isEmpty()) {
                            String propValue = propNode.get("Value").asText();
                            valueMap.put(propName, new String(DatatypeConverter.parseBase64Binary(propValue)));
                            System.out.println("Key:" + propName);
                            System.out.println("Value:" + valueMap.get(propName));
                        }
                    }
                }
            } catch (Throwable e) {
                throw new Exception("Failed to load properties. Ensure that Consul URL [" + consulServerUri + "] is correct.", e);
            }
        }
    }

    /**
     * @return
     */
    private static boolean isConsulServerConfigured() {
        return System.getenv("CONSULSERVER_PORT") != null;
    }

    private static void resolveTokens(Map<String, String> tokenMap) throws Exception {

        Path source = Paths.get(PROFILE_ROOT_DIR, "pcf.substvar");

        if (Files.isSymbolicLink(source)) {
            source = Files.readSymbolicLink(source);
        }

        File originalFile = source.toFile();
        // Construct the new file that will later be renamed to the original
        // filename.
        Path target = Paths.get(PROFILE_ROOT_DIR, "pcf_updated.substvar");
        File tempFile = target.toFile();

        try (PrintWriter writer = new PrintWriter(tempFile, StandardCharsets.UTF_8.toString());
                BufferedReader br = new BufferedReader(new FileReader(originalFile))) {

            String line;
            while ((line = br.readLine()) != null) {
                while (line.contains(TOKEN_DELIMITER)) {
                    String oldLine = line;
                    Pattern p = Pattern.compile(pattern);
                    Matcher m = p.matcher(line);
                    StringBuffer sb = new StringBuffer();
                    while (m.find()) {
                        String var = m.group(1);
                        String val = tokenMap.get(var);
                        if (val == null) {
                            throw new Exception("Value not found for Token [" + var + "]. Ensure environment variable is set.");
                        }
                        m.appendReplacement(sb, "");
                        sb.append(val);
                    }
                    m.appendTail(sb);
                    line = sb.toString();

                    if (line.equals(oldLine)) {
                        break;
                    }
                }

                // Replace lookupValue tag with value tag
                if (line.contains("lookupValue")) {
                    line = line.replace("lookupValue", "value");
                }

                writer.println(line);
            }
            writer.flush();
        }

        // Delete the original file
        if (!originalFile.delete()) {
            System.out.println("Could not delete file");
            return;
        }

        // Rename the new file to the filename the original file had.
        if (!tempFile.renameTo(originalFile)) {
            System.out.println("Could not rename file");
        }

    }

    private static void disable_ssl_verification() {

        try {

            // Create a trust manager that does not validate certificate chains
            TrustManager[] trustAllCerts = new TrustManager[] { new X509TrustManager() {
                @Override
                public java.security.cert.X509Certificate[] getAcceptedIssuers() {
                    return null;
                }

                @Override
                public void checkClientTrusted(X509Certificate[] certs, String authType) {
                }

                @Override
                public void checkServerTrusted(X509Certificate[] certs, String authType) {
                }
            } };

            // Install the all-trusting trust manager
            SSLContext sc;
            sc = SSLContext.getInstance("SSL");
            sc.init(null, trustAllCerts, new java.security.SecureRandom());
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());

            // Create all-trusting host name verifier
            HostnameVerifier allHostsValid = new HostnameVerifier() {
                @Override
                public boolean verify(String hostname, SSLSession session) {
                    return true;
                }
            };

            // Install the all-trusting host verifier
            HttpsURLConnection.setDefaultHostnameVerifier(allHostsValid);

        } catch (NoSuchAlgorithmException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        } catch (KeyManagementException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }
}
