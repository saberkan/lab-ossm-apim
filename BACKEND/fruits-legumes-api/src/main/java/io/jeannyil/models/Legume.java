package io.jeannyil.models;

import java.util.Objects;

import io.quarkus.runtime.annotations.RegisterForReflection;

/**
 * A REST entity representing a legume.
 */
@RegisterForReflection // Lets Quarkus register this class for reflection during the native build
public class Legume {
    private String name;
    private String description;

    public Legume() {
    }

    public Legume(String name, String description) {
        this.name = name;
        this.description = description;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof Legume)) {
            return false;
        }

        Legume other = (Legume) obj;

        return Objects.equals(other.name, this.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(this.name);
    }
}
