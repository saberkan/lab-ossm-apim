package io.jeannyil;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.Matchers.containsInAnyOrder;

/**
 * JVM mode tests.
 */
@QuarkusTest
public class FruitsAndLegumesApiRouteTest {

    @Test
    public void fruits() {

        /* Assert the initial fruits are there */
        given().relaxedHTTPSValidation()
                .when().get("/fruits")
                .then()
                .statusCode(200)
                .body(
                        "$.size()", is(4),
                        "name", containsInAnyOrder("Apple", "Pineapple", "Mango", "Banana"),
                        "description", containsInAnyOrder("Winter fruit", "Tropical fruit", "Tropical fruit", "Tropical fruit"));

        /* Add a new fruit */
        given().relaxedHTTPSValidation()
                .body("{\"name\": \"Pear\", \"description\": \"Winter fruit\"}")
                .header("Content-Type", "application/json")
                .when()
                .post("/fruits")
                .then()
                .statusCode(200)
                .body(
                        "$.size()", is(5),
                        "name", containsInAnyOrder("Apple", "Pineapple", "Mango", "Banana", "Pear"),
                        "description", containsInAnyOrder("Winter fruit", "Tropical fruit", "Tropical fruit", "Tropical fruit", "Winter fruit"));
    }

    @Test
    public void legumes() {
        given().relaxedHTTPSValidation()
                .when().get("/legumes")
                .then()
                .statusCode(200)
                .body("$.size()", is(2),
                        "name", containsInAnyOrder("Carrot", "Zucchini"),
                        "description", containsInAnyOrder("Root vegetable, usually orange", "Summer squash"));
    }

}
