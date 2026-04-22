import 'package:equatable/equatable.dart';
import 'package:vrs_transport_manager/features/payment/domain/entities/payment.dart';

sealed class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentLoaded extends PaymentState {
  final List<Payment> payments;

  const PaymentLoaded({required this.payments});

  @override
  List<Object?> get props => [payments];
}

class PaymentOperationSuccess extends PaymentState {
  final String message;

  const PaymentOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}
