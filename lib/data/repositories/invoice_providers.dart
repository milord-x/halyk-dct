import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../real/real_acceptance_repository.dart';
import '../real/real_invoice_repository.dart';

final invoiceRepoProvider = Provider<RealInvoiceRepository>(
  (ref) => RealInvoiceRepository(ref.read(dioProvider)),
);

final acceptanceRepoProvider = Provider<RealAcceptanceRepository>(
  (ref) => RealAcceptanceRepository(ref.read(dioProvider)),
);
