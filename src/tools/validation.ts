//Functions-helpers for validating different objects
import models from "../schemas/app_models.json";
import Ajv from "ajv";
import ConnectionBody from "../classes/connectionBody";
import JobBody from "../classes/jobBody";
import Step from "../classes/step";

type ValidationResult = {
  isValid: boolean;
  errorList?: string;
};

export default class Validation {
  /**
   * Validates object accordingly to schema. Returns validation result and (optional) error list
   * @param {ConnectionBody | Record<string, unknown>} object Object for validation
   * @param {boolean | object} schema `json` schema for object validation
   * @returns {ValidationResult} Result of validation and (in case of failure) error list
   */
  private static validateObject(
    object: ConnectionBody | JobBody | Step,
    schema: boolean | object
  ): ValidationResult {
    const ajv = new Ajv();
    /* not used, but in case will be needed for multiple json schema validations
    if(extraSchemaList)
        extraSchemaList.forEach(function(e) { ajv.addSchema(e) }); 
    */
    const validate: Ajv.ValidateFunction = ajv.compile(schema);
    const valid: boolean = validate(object) as boolean;
    if (!valid) {
      return { isValid: false, errorList: ajv.errorsText(validate.errors) };
    } else return { isValid: true };
  }

  /**
   * Validates `Job` accordingly to schema. Returns validation result and (optional) error list
   * @param {JobBody} job Job object for validation
   * @returns {ValidationResult} Result of validation and (in case of failure) error list
   */
  public static validateJob(job: JobBody): ValidationResult {
    models.jobSchema["required"] = models.jobSchemaRequired;
    return this.validateObject(job, models.jobSchema);
  }

  /**
   * Validates connetion accordingly to schema. Returns validation result and (optional) error list
   * @param {ConnectionBody} connection Connection object for validation
   * @returns {ValidationResult} Result of validation and (in case of failure) error list
   */
  public static validateConnection(
    connection: ConnectionBody
  ): ValidationResult {
    models.connectionSchema["required"] = models.connectionSchemaRequired;
    return Validation.validateObject(connection, models.connectionSchema);
  }
  /**
   * Validates list of steps accordingly to schema. Returns validation result and (optional) error list
   * @param {Array<Record<string, unknown>>} connection Connection object for validation
   * @returns {ValidationResult} Result of validation and (in case of failure) error list
   */
  public static validateStepList(stepList: Array<Step>): ValidationResult {
    models.stepSchema["required"] = models.stepSchemaRequired;
    for (let i = 0; i < stepList.length; i++) {
      const validationResult: ValidationResult = Validation.validateObject(
        stepList[i],
        models.stepSchema
      );
      if (!validationResult.isValid) return validationResult;
    }
    return { isValid: true };
  }
}
