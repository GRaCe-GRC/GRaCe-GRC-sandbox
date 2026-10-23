import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class HealthCheck {

	public static void main(String[] args) {
		try {
			HttpRequest request = HttpRequest.newBuilder(URI.create(args[0])).timeout(Duration.ofSeconds(5)).build();
			HttpResponse<String> response = HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
			System.exit(response.statusCode() == 200 && response.body().contains("\"UP\"") ? 0 : 1);
		}
		catch (Exception ex) {
			System.exit(1);
		}
	}

}
