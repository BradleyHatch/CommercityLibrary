import React from 'react';
import PropTypes from 'prop-types';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import 'javascript_lib/styles/modal.scss'


class Modal extends React.Component {

  constructor(props) {
    super(props);
  }

  _getModalClassNames() {
    let classNames = "modal";

    classNames += this.props.open ? " modal--open" : " modal--closed";

    if(this.props.className) {
      classNames += " " + this.props.className;
    }

    return classNames;
  }

  _render_content() {
    return this.props.open ? this.props.children : null
  }

  render() {
    return(
      <div>
        <div onClick={this.props.toggle} className={this._getModalClassNames()} />
        <div
          className={
            this.props.open
            ? "modal__content-container modal__content-container--open"
            : "modal__content-container modal__content-container--closed"
          }
        >
          <div className="modal__content">
            {this._render_content()}
          </div>
        </div>
      </div>
    );
  }
}

Modal.propTypes = {
  toggle: PropTypes.func,
  children: PropTypes.node,
  className: PropTypes.string,
  open: PropTypes.bool
};

Modal.defaultProps = {
  children: null,
  className: null,
  open: false
};

export default applyComponentDecorators(Modal);
