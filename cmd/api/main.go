package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/example-service/internal/httpapi"
)

const (
	serverAddress     = ":8080"
	readHeaderTimeout = 5 * time.Second
	readTimeout       = 10 * time.Second
	writeTimeout      = 10 * time.Second
	idleTimeout       = 60 * time.Second
	shutdownTimeout   = 10 * time.Second
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	if err := run(context.Background(), logger); err != nil {
		logger.Error("api stopped", slog.Any("error", err))
		os.Exit(1)
	}
}

func run(parentContext context.Context, logger *slog.Logger) error {
	server := &http.Server{
		Addr:              serverAddress,
		Handler:           httpapi.NewHandler(),
		ReadHeaderTimeout: readHeaderTimeout,
		ReadTimeout:       readTimeout,
		WriteTimeout:      writeTimeout,
		IdleTimeout:       idleTimeout,
	}

	signalContext, stop := signal.NotifyContext(
		parentContext,
		os.Interrupt,
		syscall.SIGTERM,
	)
	defer stop()

	serverErrors := make(chan error, 1)
	go func() {
		logger.Info("api listening", slog.String("address", server.Addr))
		serverErrors <- server.ListenAndServe()
	}()

	select {
	case err := <-serverErrors:
		return normalizeServerError(err)
	case <-signalContext.Done():
	}

	shutdownContext, cancel := context.WithTimeout(
		context.WithoutCancel(signalContext),
		shutdownTimeout,
	)
	defer cancel()

	if err := server.Shutdown(shutdownContext); err != nil {
		return forceClose(server, serverErrors, err)
	}

	return normalizeServerError(<-serverErrors)
}

func forceClose(server *http.Server, serverErrors <-chan error, shutdownError error) error {
	var closeError error
	if err := server.Close(); err != nil {
		closeError = fmt.Errorf("close http server: %w", err)
	}

	return errors.Join(
		fmt.Errorf("shutdown http server: %w", shutdownError),
		closeError,
		normalizeServerError(<-serverErrors),
	)
}

func normalizeServerError(err error) error {
	if err == nil || errors.Is(err, http.ErrServerClosed) {
		return nil
	}

	return fmt.Errorf("serve http: %w", err)
}
