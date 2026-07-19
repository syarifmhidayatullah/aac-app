package email

import (
	"fmt"

	"github.com/resend/resend-go/v2"
)

// Mailer mengirim email transaksional lewat Resend. nil-able di
// service.Auth — kalau RESEND_API_KEY tidak di-set, pengiriman email
// di-skip (log warning), registrasi tetap jalan.
type Mailer struct {
	client *resend.Client
	from   string
}

func New(apiKey, from string) *Mailer {
	return &Mailer{client: resend.NewClient(apiKey), from: from}
}

func (m *Mailer) SendVerification(toEmail, toName, verifyURL string) error {
	html := fmt.Sprintf(`<!DOCTYPE html>
<html>
<body style="font-family:Helvetica,Arial,sans-serif;background:#f1f5f9;padding:40px 16px;margin:0">
  <div style="max-width:480px;margin:0 auto;background:#fff;border-radius:16px;padding:40px;box-shadow:0 1px 3px rgba(0,0,0,0.1)">
    <h1 style="font-size:20px;margin:0 0 16px">Verifikasi Email Kamu</h1>
    <p style="color:#334155;font-size:14px;line-height:1.5">Halo %s, klik tombol di bawah untuk memverifikasi email kamu di aplikasi AAC.</p>
    <p style="margin:24px 0">
      <a href="%s" style="display:inline-block;background:#4f46e5;color:#fff;text-decoration:none;padding:12px 24px;border-radius:8px;font-weight:600">Verifikasi Email</a>
    </p>
    <p style="color:#94a3b8;font-size:12px">Link berlaku 24 jam. Abaikan email ini jika kamu tidak mendaftar di aplikasi AAC.</p>
  </div>
</body>
</html>`, toName, verifyURL)

	_, err := m.client.Emails.Send(&resend.SendEmailRequest{
		From:    m.from,
		To:      []string{toEmail},
		Subject: "Verifikasi Email AAC",
		Html:    html,
	})
	return err
}
