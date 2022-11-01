function productDropzone() {
  if ($(".dropzone.product").length) {
    var $dropzone = $(".dropzone.product");
    var myDropzone = new Dropzone(".dropzone.product", {
      url:
        "/admin/products/" +
        $dropzone.attr("data-product-id") +
        "/product_image",
      dictDefaultMessage: ""
    });

    myDropzone.on("complete", function(file) {
      $.post(
        "/admin/products/" +
          $dropzone.attr("data-product-id") +
          "/reload_images"
      );
    });

    myDropzone.on("addedfile", function(file) {
      $dropzone.addClass("dz-uploading");
      previewEvent();
    });

    myDropzone.on("queuecomplete", function(file) {
      $dropzone.removeClass("dz-uploading");
    });
  }
}

// This function below is for setting up dropzone dynamically based upon the data
// attributes that the image_upload partial contains. The data attributes should
// always be controller, object id and image id.
// Drag and drop setting a preview image also included in this function
function defaultDropzone() {
  var dropzoneType = "";
  var dropzoneName = "";
  var $dropzone = "";
  var dropzoneData = "";

  if (
    $(".dropzone").length &&
    $(".dropzone").data("model-type") &&
    $(".dropzone").data("model-type").length > 0
  ) {
    $dropzone = $(".dropzone");
    dropzoneType = $(".dropzone").data("model-type");
    dropzoneData = $dropzone.attr("data-" + dropzoneType + "-id");
  }

  if (dropzoneType.length > 0) {
    var myDropzone = new Dropzone(".dropzone", {
      url: "/admin/" + dropzoneType + "/" + dropzoneData + "/dropzone_image",
      dictDefaultMessage: ""
    });

    myDropzone.on("complete", function(file) {
      $.post("/admin/" + dropzoneType + "/" + dropzoneData + "/reload_images");
    });

    myDropzone.on("queuecomplete", function(file) {
      $dropzone.removeClass("dz-uploading");
    });

    myDropzone.on("addedfile", function(file) {
      $dropzone.addClass("dz-uploading");
      previewEvent();
    });

    featuredImage(dropzoneType);
  }

  if ($("#preview_drag__target").length && dropzoneData.length > 0) {
    previewEvent();

    $("#preview_drag__target").droppable({
      hoverClass: "hovering",
      drop: function(event, ui) {
        setPreviewImage(
          dropzoneData,
          $(ui.draggable).attr("data-image-id"),
          dropzoneType
        );
      }
    });

    $(".image_container.draggable img").on("drag", function(event, ui) {});
  }
}

function previewEvent() {
  $(".image_container.draggable img").draggable({
    revert: true,
    drag: function(event, ui) {
      setPreviewHeights();
    }
  });
}

function featuredImage(type) {
  $(".image_featured input").on("click", function() {
    var checked = $(this).is(":checked");
    $(".image_featured input").prop("checked", false);
    $(this).prop("checked", checked);
    $.post(
      "/admin/" +
        type +
        "/" +
        $(this).data("obj-id") +
        "/set_featured_image?image_id=" +
        $(this).data("image-id")
    );
  });
}

function setPreviewImage(objId, imageId, type) {
  $.post(
    "/admin/" + type + "/" + objId + "/set_preview_image?image_id=" + imageId
  );
}

function setPreviewHeights() {
  var $preview = $("[data-preview-target='true']");
  $("[data-preview-overlay='true']")
    .width($preview.outerWidth())
    .height($preview.outerHeight());
}
