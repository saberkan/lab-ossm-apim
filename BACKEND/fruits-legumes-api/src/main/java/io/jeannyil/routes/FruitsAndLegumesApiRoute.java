package io.jeannyil.routes;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Set;

import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.apache.camel.CamelContext;
import org.apache.camel.Exchange;
import org.apache.camel.LoggingLevel;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;
import org.apache.camel.model.rest.RestBindingMode;

import io.jeannyil.models.Fruit;
import io.jeannyil.models.Legume;

/* Camel route definition

/!\ The @ApplicationScoped annotation is required for @Inject and @ConfigProperty to work in a RouteBuilder. 
	Note that the @ApplicationScoped beans are managed by the CDI container and their life cycle is thus a bit 
	more complex than the one of the plain RouteBuilder. 
	In other words, using @ApplicationScoped in RouteBuilder comes with some boot time penalty and you should 
	therefore only annotate your RouteBuilder with @ApplicationScoped when you really need it. */
@ApplicationScoped
public class FruitsAndLegumesApiRoute extends RouteBuilder {
    private final Set<Fruit> fruits = Collections.synchronizedSet(new LinkedHashSet<>());
    private final Set<Legume> legumes = Collections.synchronizedSet(new LinkedHashSet<>());

    @Inject
	CamelContext camelctx;

    public FruitsAndLegumesApiRoute() {

        /* Let's add some initial fruits */
        this.fruits.add(new Fruit("Apple", "Winter fruit"));
        this.fruits.add(new Fruit("Pineapple", "Tropical fruit"));
        this.fruits.add(new Fruit("Mango", "Tropical fruit"));
        this.fruits.add(new Fruit("Banana", "Tropical fruit"));

        /* Let's add some initial legumes */
        this.legumes.add(new Legume("Carrot", "Root vegetable, usually orange"));
        this.legumes.add(new Legume("Zucchini", "Summer squash"));
    }

    @Override
    public void configure() throws Exception {

        // Enable Stream caching
        camelctx.setStreamCaching(true);
        // Enable use of breadcrumbId
        camelctx.setUseBreadcrumb(true);

        // Catch unexpected exceptions
		onException(Exception.class)
            .handled(true)
            .maximumRedeliveries(0)
            .log(LoggingLevel.ERROR, ">>> Caught exception: ${exception.stacktrace}")
            .setHeader(Exchange.HTTP_RESPONSE_CODE, constant(Response.Status.INTERNAL_SERVER_ERROR.getStatusCode()))
			.setHeader(Exchange.HTTP_RESPONSE_TEXT, constant(Response.Status.INTERNAL_SERVER_ERROR.getReasonPhrase()))
			.setHeader(Exchange.CONTENT_TYPE, constant(MediaType.TEXT_PLAIN))
			.setBody(simple("${exception}"))
            .log(LoggingLevel.INFO, ">>> OUT: headers:[${headers}] - body:[${body}]")
        ;
        
        //REST configuration with Camel Quarkus Platform HTTP component
        restConfiguration()
            .component("platform-http")
            .enableCORS(true)
            .bindingMode(RestBindingMode.off) // RESTful responses will be explicitly marshaled for logging purposes
            .dataFormatProperty("prettyPrint", "true")
            .contextPath("/")
        ;

        // REST endpoint for the Service OpenAPI document
        rest()
            .produces(MediaType.APPLICATION_JSON)
            .get("/openapi.json")
                .id("get-oas-route")
                .description("Gets the OpenAPI document for this service in JSON format")
                .route()
                    .log(LoggingLevel.INFO, ">>> IN: headers:[${headers}] - body:[${body}]")
                    .setHeader(Exchange.CONTENT_TYPE, constant("application/vnd.oai.openapi+json"))
                    .setBody().constant("resource:classpath:openapi/openapi.json")
                    .log(LoggingLevel.INFO, ">>> OUT: headers:[${headers}] - body:[${body}]").id("log-openapi-doc-response")
                .end()
        ;
        
        // REST endpoint for the fruits API
        rest("/fruits")
            .get()
                .id("get-fruits-route")
                .produces(MediaType.APPLICATION_JSON)
                .description("Returns a list of hard-coded and added fruits")
                // Call the getFruits route
                .to("direct:getFruits")
            
            // Adds a fruit
            .post()
                .id("add-fruit-route")
                .consumes(MediaType.APPLICATION_JSON)
                .produces(MediaType.APPLICATION_JSON)
                .description("Adds a fruit")
                // Call the getFruits route
                .to("direct:addFruit")
        ;

        // REST endpoint for the legumes API
        rest("/legumes")
            .get()
                .id("get-legumes-route")
                .produces(MediaType.APPLICATION_JSON)
                .description("Returns a list of hard-coded legumes")
                // Call the getFruits route
                .to("direct:getLegumes")
        ;
        
        // Implements getFruits operation
        from("direct:getFruits")
            .routeId("getFruits")
            .log(LoggingLevel.INFO, ">>> Processing GET fruits request...")
            .setBody().constant(fruits)
            .marshal().json(JsonLibrary.Jackson, true)
            .log(LoggingLevel.INFO, ">>> Sending GET fruits response: ${body}")
        ;

        // Implements addFruit operation
        from("direct:addFruit")
            .routeId("addFruit")
            .log(LoggingLevel.INFO, ">>> Processing POST fruits request: ${body}")
            .unmarshal()
                .json(JsonLibrary.Jackson, Fruit.class)
            .process()
                .body(Fruit.class, fruits::add)
            .setBody().constant(fruits)
            .marshal().json(JsonLibrary.Jackson, true)
            .log(LoggingLevel.INFO, ">>> Processing POST fruits DONE: ${body}")
        ;
        
        // Implements getLegumes operation
        from("direct:getLegumes")
            .routeId("getLegumes")
            .log(LoggingLevel.INFO, ">>> Processing GET legumes request...")
            .setBody().constant(legumes)
            .marshal().json(JsonLibrary.Jackson, true)
            .log(LoggingLevel.INFO, ">>> Sending GET legumes response: ${body}")
        ;

    }
}
