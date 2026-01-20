public with sharing class AgentforceBookingInputAction {

    // ===== Request Wrapper =====
    public class BookingInput {
        @InvocableVariable(required=true)
        public String activityType;

        @InvocableVariable(required=true)
        public Datetime startDateTime;

        @InvocableVariable
        public Decimal guestPaidAmount;

        @InvocableVariable
        public String paymentStatus;

        @InvocableVariable
        public String cancellationReason;

        @InvocableVariable
        public Decimal latitude;

        @InvocableVariable
        public Decimal longitude;
    }

    // ===== Response Wrapper =====
    public class BookingContext {
        @InvocableVariable
        public String activityType;

        @InvocableVariable
        public Datetime startDateTime;

        @InvocableVariable
        public Decimal guestPaidAmount;

        @InvocableVariable
        public String paymentStatus;

        @InvocableVariable
        public String cancellationReason;

        @InvocableVariable
        public Decimal latitude;

        @InvocableVariable
        public Decimal longitude;
    }

    // ===== Invocable Method =====
    @InvocableMethod(
        label='Provide Booking Context'
        description='Accepts booking details provided by a human agent for refund and cancellation evaluation'
    )
    public static List<BookingContext> provideBookingContext(List<BookingInput> inputs) {

        List<BookingContext> responses = new List<BookingContext>();

        for (BookingInput input : inputs) {
            BookingContext ctx = new BookingContext();
            ctx.activityType       = input.activityType;
            ctx.startDateTime      = input.startDateTime;
            ctx.guestPaidAmount    = input.guestPaidAmount;
            ctx.paymentStatus      = input.paymentStatus;
            ctx.cancellationReason = input.cancellationReason;
            ctx.latitude           = input.latitude;
            ctx.longitude          = input.longitude;

            responses.add(ctx);
        }

        return responses;
    }
}