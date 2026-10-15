const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');

const outputDirectory = path.resolve(__dirname, '../../generated-pdfs');

function safeFileName(value) {
  return String(value).replace(/[^a-zA-Z0-9_-]/g, '_');
}

function generateAppointmentPdf(appointment) {
  fs.mkdirSync(outputDirectory, { recursive: true });

  const fileName = `${safeFileName(appointment.appointment_number)}.pdf`;
  const absolutePath = path.join(outputDirectory, fileName);
  const relativePath = path.posix.join('generated-pdfs', fileName);

  return new Promise((resolve, reject) => {
    const document = new PDFDocument({ margin: 50 });
    const output = fs.createWriteStream(absolutePath);

    output.on('finish', () => resolve({ fileName, relativePath }));
    output.on('error', reject);
    document.on('error', reject);

    document.pipe(output);
    document.fontSize(20).text('Hospital Appointment Confirmation', { align: 'center' });
    document.moveDown();
    document.fontSize(12);
    document.text(`Appointment number: ${appointment.appointmentNumber}`);
    document.text(`Patient: ${appointment.patientFirstName} ${appointment.patientLastName || ''}`);
    document.text(`Phone: ${appointment.patientPhone}`);
    document.text(`Department: ${appointment.departmentName}`);
    document.text(`Doctor: Dr. ${appointment.doctorFirstName} ${appointment.doctorLastName || ''}`);
    document.text(`Room: ${appointment.roomNumber || 'To be assigned'}`);
    document.text(`Date: ${appointment.appointmentDate}`);
    document.text(`Time: ${appointment.appointmentTime || 'Immediate attention'}`);
    document.text(`Token: ${appointment.tokenNumber || 'Emergency priority'}`);
    document.text(`Priority: ${appointment.priority}`);
    document.text(`Status: ${appointment.status}`);
    document.moveDown();
    document.text('Symptoms:');
    document.text(appointment.symptoms);
    document.moveDown();
    document.text('Please bring this confirmation and arrive at the assigned department.');
    document.end();
  });
}

module.exports = { generateAppointmentPdf };
