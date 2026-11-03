// Démo TOTP (RFC 6238) en Java 25, sans aucune dépendance.
//
//   java Totp.java enroll | qrencode -t ansiutf8   -> crée un secret et affiche le QR code
//   java Totp.java                                  -> affiche le code courant, en direct
//
// Fichier source "compact" (Java 25) : pas de classe, pas d'import,
// java.base est importé automatiquement.

final Path SECRET_FILE = Path.of("demo-secret.txt");

void main(String[] args) throws Exception {
    if (args.length > 0 && args[0].equals("enroll")) {
        byte[] secret = new byte[20];                    // 160 bits, taille recommandée par la RFC
        new SecureRandom().nextBytes(secret);
        String b32 = base32(secret);
        Files.writeString(SECRET_FILE, b32);
        IO.println("otpauth://totp/Apero:demo?secret=" + b32 + "&issuer=Apero");
        return;
    }

    byte[] key = unbase32(Files.readString(SECRET_FILE).strip());
    while (true) {
        long now = Instant.now().getEpochSecond();
        IO.print("\r  %s   (encore %2d s) ".formatted(totp(key, now / 30), 30 - now % 30));
        Thread.sleep(1000);
    }
}

// Tout l'algorithme TOTP : HMAC-SHA1 du numéro de tranche de 30 s, puis troncature à 6 chiffres.
String totp(byte[] key, long counter) throws Exception {
    Mac mac = Mac.getInstance("HmacSHA1");
    mac.init(new SecretKeySpec(key, "HmacSHA1"));
    byte[] h = mac.doFinal(ByteBuffer.allocate(8).putLong(counter).array());

    int offset = h[h.length - 1] & 0x0F;                            // troncature dynamique
    int code = ByteBuffer.wrap(h, offset, 4).getInt() & 0x7FFFFFFF; // 31 bits, sans le signe
    return "%06d".formatted(code % 1_000_000);
}

// --- Base32 (RFC 4648), le format du secret dans le QR code. Le JDK n'a que Base64. ---

final String B32 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

String base32(byte[] data) {
    var sb = new StringBuilder();
    int buffer = 0, bits = 0;
    for (byte b : data) {
        buffer = (buffer << 8) | (b & 0xFF);
        bits += 8;
        while (bits >= 5) {
            sb.append(B32.charAt((buffer >> (bits - 5)) & 31));
            bits -= 5;
        }
    }
    if (bits > 0) sb.append(B32.charAt((buffer << (5 - bits)) & 31));
    return sb.toString();
}

byte[] unbase32(String s) {
    var out = new ByteArrayOutputStream();
    int buffer = 0, bits = 0;
    for (char c : s.toUpperCase().toCharArray()) {
        if (c == '=') break;
        buffer = (buffer << 5) | B32.indexOf(c);
        bits += 5;
        if (bits >= 8) {
            out.write((buffer >> (bits - 8)) & 0xFF);
            bits -= 8;
        }
    }
    return out.toByteArray();
}
