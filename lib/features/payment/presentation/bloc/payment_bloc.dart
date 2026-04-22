import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vrs_transport_manager/features/payment/domain/repositories/payment_repository.dart';
import 'package:vrs_transport_manager/features/payment/domain/usecases/payment_usecases.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final GetPaymentsUseCase _getPayments;
  final GetPaymentsForDateRangeUseCase _getPaymentsForDateRange;
  final CreatePaymentUseCase _createPayment;
  final DeletePaymentUseCase _deletePayment;
  final PaymentRepository _repository;
  StreamSubscription? _paymentsSubscription;

  PaymentBloc({
    required GetPaymentsUseCase getPayments,
    required GetPaymentsForDateRangeUseCase getPaymentsForDateRange,
    required CreatePaymentUseCase createPayment,
    required DeletePaymentUseCase deletePayment,
    required PaymentRepository repository,
  })  : _getPayments = getPayments,
        _getPaymentsForDateRange = getPaymentsForDateRange,
        _createPayment = createPayment,
        _deletePayment = deletePayment,
        _repository = repository,
        super(const PaymentInitial()) {
    on<PaymentLoadAll>(_onLoadAll);
    on<PaymentPaymentsUpdated>(_onPaymentsUpdated);
    on<PaymentCreate>(_onCreate);
    on<PaymentDelete>(_onDelete);
    on<PaymentLoadForDateRange>(_onLoadForDateRange);
  }

  Future<void> _onLoadAll(
    PaymentLoadAll event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());

    final result = await _getPayments();
    result.fold(
      (failure) => emit(PaymentError(failure.message)),
      (payments) => emit(PaymentLoaded(payments: payments)),
    );

    // Start listening for real-time updates
    await _paymentsSubscription?.cancel();
    _paymentsSubscription = _repository.watchPayments().listen(
      (payments) => add(PaymentPaymentsUpdated(payments)),
      onError: (_) {},
    );
  }

  void _onPaymentsUpdated(
    PaymentPaymentsUpdated event,
    Emitter<PaymentState> emit,
  ) {
    emit(PaymentLoaded(payments: event.payments));
  }

  Future<void> _onCreate(
    PaymentCreate event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    final result = await _createPayment(event.payment);
    result.fold(
      (failure) => emit(PaymentError(failure.message)),
      (_) => emit(
          const PaymentOperationSuccess('Payment recorded successfully')),
    );
  }

  Future<void> _onDelete(
    PaymentDelete event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    final result = await _deletePayment(event.id);
    result.fold(
      (failure) => emit(PaymentError(failure.message)),
      (_) => emit(
          const PaymentOperationSuccess('Payment deleted successfully')),
    );
    // Reload after delete
    if (result.isRight()) {
      final payments = await _getPayments();
      payments.fold(
        (_) {},
        (data) => emit(PaymentLoaded(payments: data)),
      );
    }
  }

  Future<void> _onLoadForDateRange(
    PaymentLoadForDateRange event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    final result =
        await _getPaymentsForDateRange(event.weekStart, event.weekEnd);
    result.fold(
      (failure) => emit(PaymentError(failure.message)),
      (payments) => emit(PaymentLoaded(payments: payments)),
    );
  }

  @override
  Future<void> close() {
    _paymentsSubscription?.cancel();
    return super.close();
  }
}
