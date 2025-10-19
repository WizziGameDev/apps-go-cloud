package main

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/log"
)

func Routes(app *fiber.App) {
	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("Hello, World!")
	})
}

func main() {
	app := fiber.New()
	Routes(app)

	err := app.Listen(":8000")
	if err != nil {
		log.Fatal(err)
	}
}
