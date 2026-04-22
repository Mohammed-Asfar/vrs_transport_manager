import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/payment/domain/entities/payment.dart';

sealed class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class PaymentLoadAll extends PaymentEvent {
  const PaymentLoadAll();
}

class PaymentCreate extends PaymentEvent {
  final Payment payment;
  const PaymentCreate(this.payment);

  @override
  List<Object?> get props => [payment];
}

class PaymentDelete extends PaymentEvent {
  final String id;
  const PaymentDelete(this.id);

  @override
  List<Object?> get props => [id];
}

class PaymentLoadForDateRange extends PaymentEvent {
  final DateTime weekStart;
  final DateTime weekEnd;
  const PaymentLoadForDateRange(this.weekStart, this.weekEnd);

  @override
  List<Object?> get props => [weekStart, weekEnd];
}

class PaymentPaymentsUpdated extends PaymentEvent {
  final List<Payment> payments;
  const PaymentPaymentsUpdated(this.payments);

  @override
  List<Object?> get props => [payments];
}
